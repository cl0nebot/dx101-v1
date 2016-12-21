class CryptoDepositWorker

  include Sidekiq::Worker
  sidekiq_options queue: :crypto_deposit

  def perform currency, txid
    CryptoDepositTransactor.receive currency, txid
  end

end
