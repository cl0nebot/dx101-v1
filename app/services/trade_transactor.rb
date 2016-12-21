class TradeTransactor

  def initialize source
    @source = source
  end

  def self.execute source
    trade = TradeTransactor.new source
    trade.execute
  end

  def execute
    process_source if @source.processing?
  end

private

  def process_source
    source_cleared_for_fok? ? trade_with_next_match : @source.cancel
  end

  def trade_with_next_match
    @target = next_match
    if @target
      process_trade
      trade_with_next_match if !@source.filled? and @source.processing?
    elsif @source.ioc? and !@source.filled?
      @source.cancel
    end
  end

  def next_match
    markets = @source.market_like_matches.limit(1)
    return markets.first unless markets.blank?
    lmts = @source.lmt_like_matches.limit(1)
    return lmts.first unless lmts.blank?
  end

  def process_trade
    set_invert
    set_trade_rate
    set_trade_quantity
    set_trade_price
    set_trade_fees
    set_trade_gains_and_losses
    ActiveRecord::Base.transaction do
      if funds_available?
        trade_transaction = TradeTransaction.new(
          source: @source,
          target: @target,
          rate: @trade_rate,
          price: @trade_price,
          quantity: @trade_quantity,
          source_fee: @source_fee,
          target_fee: @target_fee
        )
        trade_transaction.save!
        source_liability = @source.lmt_like? ? @source.user.find_account(:liability, :user_trade_holdings) : @source.user.find_account(:liability, :user_liability)
        source_sales = @source.user.find_account :revenue, :user_transaction_sales
        target_liability = @target.lmt_like? ? @target.user.find_account(:liability, :user_trade_holdings) : @target.user.find_account(:liability, :user_liability)
        target_sales = @target.user.find_account :revenue, :user_transaction_sales
        transaction_data = {
          related: trade_transaction,
          transaction_type: :trade,
          debits: [
            # Source and Target Loses with Fees
            {account: source_liability, amount: (@source_loss + @source_fee)},
            {account: target_liability, amount: (@target_loss + @target_fee)}
          ],
          credits: [
            # Source and Target Gains
            {account: source_liability, amount: @source_gain},
            {account: target_liability, amount: @target_gain},
            # Company Earns Revenue
            {account: source_sales, amount: @source_fee},
            {account: target_sales, amount: @target_fee}
          ]
        }
        transaction = Finance::Transaction.build transaction_data
        transaction.save!
        @source.quantity_filled = @source.quantity_filled + @trade_quantity
        @target.quantity_filled = @target.quantity_filled + (@invert ? @trade_price : @trade_quantity)
        if @source.filled?
          @source.status = :complete
          @source.completed_at = Time.now
        elsif @source.ioc?
          @source.status = :canceled
          @source.canceled_at = Time.now
        end
        if @target.filled?
          @target.status = :complete
          @target.completed_at = Time.now
        elsif @target.ioc?
          @target.status = :canceled
          @target.canceled_at = Time.now
        end
        @source.save!
        @target.save!
        trigger_stop_like_trades @source.quantity_currency, @source.rate_currency, @trade_rate.fractional
      end
    end
  end

  def set_invert
    @invert = (@source.quantity_currency == @target.rate_currency)
  end

  def set_trade_rate
    last_rate = MarketData.last_rate @source.quantity_currency, @source.rate_currency
    if @source.market_like? and @target.market_like?
      @trade_rate = last_rate
    elsif @source.lmt_like? and @target.lmt_like? or @target.lmt_like?
      # This will be the only possible clause if there has not been a transaction with this pair yet
      @trade_rate = @invert ? (BigDecimal.new(1)/@target.rate.amount).to_money(@source.rate_currency) : @target.rate
    elsif @source.lmt_like?
      @trade_rate = @source.rate
      @trade_rate = last_rate if last_rate and ((@source.buy? and last_rate < @trade_rate) or (@source.sell? and last_rate > @trade_rate))
    end
    Money.add_rate @source.quantity_currency, @source.rate_currency, @trade_rate.amount
    Money.add_rate @source.rate_currency, @source.quantity_currency, (BigDecimal.new(1)/@trade_rate.amount)
  end

  def set_trade_quantity
    @trade_quantity = (@source.quantity_required > @target.quantity_required ? @target.quantity_required : @source.quantity_required).exchange_to(@source.quantity_currency)
  end

  def set_trade_price
    @trade_price = @trade_quantity.exchange_to @source.rate_currency
  end

  def set_trade_fees
    @source_fee = (@source.buy? ? @trade_price : @trade_quantity) * @source.fee
    @target_fee = (@invert ? (@target.buy? ? @trade_quantity : @trade_price) : 
                             (@target.buy? ? @trade_price : @trade_quantity)) * @target.fee
    
    # TODO: Remove this hack to set the trade fees to zero
    @source_fee = @source_fee - @source_fee
    @target_fee = @target_fee - @target_fee
  end

  def set_trade_gains_and_losses
    @source_gain = @source.buy? ? @trade_quantity : @trade_price
    @target_gain = (@invert ? (@target.buy? ? @trade_price : @trade_quantity) :
                              (@target.buy? ? @trade_quantity : @trade_price))
    @source_loss = @target_gain
    @target_loss = @source_gain
  end

  def funds_available?
    funds_available = true
    unless @source.lmt_like? or @source.can_cover?(@trade_price.exchange_to(@source_fee.currency) + @source_fee)
      funds_available = false
      @source.set_pending_funds
    end
    unless @target.lmt_like? or @target.can_cover?(@trade_price.exchange_to(@target_fee.currency) + @target_fee)
      funds_available = false
      @target.set_pending_funds
    end
    funds_available
  end

  def trigger_stop_like_trades quantity_currency, rate_currency, rate_subunit
    trades = Trade.select("*, IF(quantity_currency = '#{rate_currency}', 1/stop_subunit, stop_subunit) AS inverted_stop_subunit")
                  .pending
                  .where('trade_type = ? OR trade_type = ?', Trade.trade_types[:stop], Trade.trade_types[:stop_lmt])
                  .where('(quantity_currency = ? AND rate_currency = ?) OR (quantity_currency = ? AND rate_currency = ?)', rate_currency, quantity_currency, quantity_currency, rate_currency)
                  .having('(((transfer_type = ? AND quantity_currency = ?) OR (transfer_type = ? AND quantity_currency = ?)) AND inverted_stop_subunit <= ?) OR (((transfer_type = ? AND quantity_currency = ?) OR (transfer_type = ? AND quantity_currency = ?)) AND inverted_stop_subunit >= ?)', 'buy', quantity_currency, 'buy', rate_currency, rate_subunit, 'sell', quantity_currency, 'sell', rate_currency, rate_subunit)
    # iterating so that the processed_at times are different at least slightly
    trades.sort_by(&:created_at).each do |t|
      t.update_attributes! status: Trade.statuses[:processing], processed_at: Time.now
      t.execute
    end
  end

  def source_cleared_for_fok?
     !@source.fok? or (@source.fok? and @source.can_fill?)
  end

end
