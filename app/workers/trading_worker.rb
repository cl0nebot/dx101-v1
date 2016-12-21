class TradingWorker
  
  include Sidekiq::Worker
  sidekiq_options queue: :trading
  
  def perform id
    trade = Trade.find id
    TradeTransactor.execute trade
  end

end
