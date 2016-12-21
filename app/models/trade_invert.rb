class TradeInvert

  require 'money'

  attr_reader :transfer_type, :trade_type, :rate_currency, :quantity_currency, :quantity, :quantity_filled, :rate, :rate_subunit, :quantity_subunit, :created_at

  def initialize trade
    @transfer_type = trade.invert_transfer_type.to_s
    @trade_type = trade.trade_type
    @quantity_currency = trade.rate_currency
    @rate_currency = trade.quantity_currency
    # rate may not exist if its a market trade
    unless trade.rate_subunit and trade.rate_subunit > 0
      @rate = MarketData.last_rate @quantity_currency, @rate_currency
      @oldrate = MarketData.last_rate @rate_currency, @quantity_currency
    else
      @rate = Money.new(BigDecimal.new(1)/trade.rate.amount*trade.quantity.currency.subunit_to_unit, trade.quantity_currency)
      @oldrate = trade.rate
    end
    Money.add_rate trade.quantity_currency, trade.rate_currency, @oldrate
    @quantity = trade.quantity.exchange_to trade.rate_currency
    @quantity_filled = trade.quantity_filled.exchange_to trade.rate_currency
    @created_at = trade.created_at
  end

  def buy?
    transfer_type == 'buy'
  end

  def sell?
    transfer_type == 'sell'
  end

  def market?
    trade_type == 'market'
  end

  def lmt?
    trade_type == 'lmt'
  end

  def stop?
    trade_type == 'stop'
  end

  def stop_lmt?
    trade_type == 'stop_lmt'
  end

  def market_like?
    market? or stop?
  end

  def lmt_like?
    lmt? or stop_lmt?
  end

  def stop_like?
    stop? or stop_lmt?
  end

  def quantity_required
    quantity - quantity_filled
  end

end
