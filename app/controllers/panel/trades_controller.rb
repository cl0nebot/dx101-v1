class Panel::TradesController < PanelController

  load_and_authorize_resource except: [:index, :create]

  def index
    cookies[:quantity_currency] = @quantity_currency = params[:quantity_currency] || cookies[:quantity_currency] || 'ltc'
    cookies[:rate_currency] = @rate_currency = params[:rate_currency] || cookies[:rate_currency] || 'xbt'
    raise "#{@quantity_currency.upcase}/#{@rate_currency.upcase} is an invalid pair" unless ((Finance.crypto_currencies+[:pmu]).include?(@quantity_currency.downcase.to_sym) and (Finance.crypto_currencies+[:pmu]).include?(@rate_currency.downcase.to_sym))
    raise "#{@quantity_currency.upcase}/#{@rate_currency.upcase} is an invalid pair" if @quantity_currency == @rate_currency
    @open_trades = @current_user.trades.advanced.open.where(quantity_currency: @quantity_currency, rate_currency: @rate_currency).order(status: :asc)
    @balance = @current_user.balance
    @market_data = MarketData.stats 24.hours
    @balance_currencies = @current_user.balance_currencies
    @market_currencies = @current_user.market_currencies
    @trades = MarketData.invert_array_of_transactions_to(@quantity_currency, @rate_currency, TradeTransaction.pair(@quantity_currency.upcase, @rate_currency.upcase).limit(10))
    @bids, @asks = Trade.bids_asks_for @quantity_currency, @rate_currency
    @pmus_sold = Finance::Asset.find_by(name: 'MUs').balance[:pmu]
    @pmus_available = Money.new(15000000, :pmu) - @pmus_sold
    @pmus_can_be_bought = @pmus_available > 0
  end

  def history
    @trades = @current_user.trades.advanced.order(status: :asc)
  end

  def new
  end

  def create
    begin
      trade_type = params[:trade_type].downcase.to_sym
      trade_type = :lmt if params[:trade_type].downcase == 'limit'
      trade_type = :stop_lmt if params[:trade_type].downcase == 'stop limit'
      trade_data = {
        transfer_type: params[:transfer_type].downcase.to_sym,
        trade_type: trade_type,
        quantity_currency: params[:currency],
        quantity: params[:quantity].to_f.abs,
        rate_currency: params[:rate_currency],
        ioc: params[:ioc],
        fok: params[:fok]
      }
      trade_data[:rate] = params[:lmt_amount].to_f.abs if params[:lmt_amount]
      trade_data[:stop_rate] = params[:stop_amount].to_f.abs if params[:stop_amount]
      trade = @current_user.trades.new trade_data
      raise 'No Market' if trade.market? and MarketData.last_rate(params[:currency], params[:rate_currency]).nil? and trade.lmt_like_matches.blank?
      if trade.save
        json = {}
      else
        msg = "Something's gone wrong, please contact support"
        msg = "Your quantity must be greather than 0" unless trade.errors[:quantity_subunit].blank?
        msg = "Your limit rate must be greather than 0" unless trade.errors[:rate_subunit].blank?
        msg = "Your stop rate must be greather than 0" unless trade.errors[:stop_subunit].blank?
        msg = trade.errors[:base] unless trade.errors[:base].blank?
        json = {error: msg}
      end
    rescue => e
      puts e
      puts e.backtrace
      json = {error: e.to_s}
    end
    respond_to do |f|
      f.json do
        render json: json
      end
    end
  end

  def show
    @transactions = @trade.transactions
  end

  def cancel
    if @trade.pending? or @trade.pending_funds? or @trade.processing?
      @trade.cancel
      redirect_to request.referrer, flash: {success: 'Your trade has been canceled'}
    else
      redirect_to request.referrer, flash: {error: 'You can not cancel this trade'}
    end
  end

  def activate
    if @trade.canceled? or @trade.pending_funds?
      @trade.reprocess
      @trade.execute
      redirect_to request.referrer, flash: {success: 'Your trade has been activated'}
    else
      redirect_to request.referrer, flash: {error: 'You can not activate this trade'}
    end
  end

  def units
    currency = params[:currency]
    amount = BigDecimal.new(params[:amount])
    begin
      currency == 'PMU' ? @current_user.buy_pmus(Money.new(amount*100, currency)) : @current_user.buy_smus(Money.new(amount*100, currency))
      json = {}
    rescue => e
      json = {error: e.to_s}
    end
    respond_to do |f|
      f.json do
        render json: json
      end
    end
  end

  def filters
    begin
      @current_user.save_setting params[:filter_type], params[:currencies]
      json = {}
    rescue => e
      puts e.backtrace
      json = {error: e.to_s}
    end
    respond_to do |f|
      f.json do
        render json: json
      end
    end
  end

end
