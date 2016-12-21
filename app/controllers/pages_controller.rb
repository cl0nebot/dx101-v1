class PagesController < ApplicationController

  force_ssl

  def index
    return redirect_to :panel_dashboard if authed?
    @page_title = "101 Digital Exchange"
    @description = "The World's Local Bitcoin Exchange. Open a Free Account Today"
    @keywords = "bitcoin exchange, bitcoin, dogecoin exchange, buy bitcoin, buy dogecoin, litecoin, litecoin exchange"
  end
 
  def agents
    @page_title = "101DX: Become an Agent and Sell Bitcoins"
  end

  def fees
    @page_title = "101DX: Trading Fees"
  end

  def privacy
    @page_title = "101DX: Privacy Policy"
  end

  def terms
    @page_title = "101DX: Terms and Conditions"
  end

  def values
   @page_title = "101DX: Our Values - What to Expect"
  end

  def markets
    cookies[:quantity_currency_external] = @quantity_currency = params[:quantity_currency] || cookies[:quantity_currency_external] || 'ltc'
    cookies[:rate_currency_external] = @rate_currency = params[:rate_currency] || cookies[:rate_currency_external] || 'xbt'
    return redirect_to markets_path((@quantity_currency == 'btc' ? 'xbt' : @quantity_currency), (@rate_currency == 'btc' ? 'xbt' : @rate_currency)), status: 301 if [@quantity_currency, @rate_currency].include? 'btc'
    raise "#{@quantity_currency.upcase}/#{@rate_currency.upcase} is an invalid pair" unless ((Finance.crypto_currencies+[:pmu]).include?(@quantity_currency.downcase.to_sym) and (Finance.crypto_currencies+[:pmu]).include?(@rate_currency.downcase.to_sym))
    raise "#{@quantity_currency.upcase}/#{@rate_currency.upcase} is an invalid pair" if @quantity_currency == @rate_currency
    @page_title = "Buy & Sell #{Finance.crypto_name_by_currency @quantity_currency} with #{Finance.crypto_name_by_currency @rate_currency} at 101DX | #{@quantity_currency.upcase}/#{@rate_currency.upcase} Market Data & Charts"
    @market_data = MarketData.stats 24.hours
    @trades = MarketData.invert_array_of_transactions_to(@quantity_currency, @rate_currency, TradeTransaction.pair(@quantity_currency.upcase, @rate_currency.upcase).limit(10))
    @bids, @asks = Trade.bids_asks_for @quantity_currency, @rate_currency
  end

end
