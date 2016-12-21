class Api::ListenerController < ApiController

  before_action :auth_required

  def deposit
    if params[:currency] and params[:txid]
      tx_exists = CryptoDeposit.where(txid: params[:txid]).length > 0
      scheduled = CryptoDepositTransactor.scheduled? params[:currency], params[:txid]
      CryptoDepositWorker.perform_async params[:currency], params[:txid] unless tx_exists or scheduled
    end
    render status: 200, nothing: true
  end

  def withdraw
  end

end
