class Panel::WalletController < PanelController

  def show
    @deposits = @current_user.crypto_deposits.viewable.includes(:crypto_address)
    @withdraws = @current_user.crypto_withdraws
  end

  def withdraw
    @balance = @current_user.balance
    @balance_currencies = @current_user.balance_currencies
    if request.post?
      @withdraw = @current_user.crypto_withdraws.new(
        currency: params[:crypto_withdraw][:currency],
        amount: params[:crypto_withdraw][:amount],
        fee: ENV["#{params[:crypto_withdraw][:currency].downcase}_withdraw_fee"],
        address: params[:crypto_withdraw][:address]
      )
      min_withdraw = ENV["#{params[:crypto_withdraw][:currency].downcase}_withdraw_min"].to_money @withdraw.currency
      if @withdraw.amount < min_withdraw
        flash.now[:error] = 'Amount does not meet the withdraw minimum.'
      elsif !@current_user.can_cover? @withdraw.amount + @withdraw.fee
        flash.now[:error] = 'Insufficient funds.'
      elsif !@withdraw.valid?
        flash.now[:error] = @withdraw.errors.full_messages.first
      else
        begin
          @withdraw.save!
          redirect_to :panel_wallet, flash: {success: 'Withdraw submitted.'}
        rescue => e
          puts e
          puts e.backtrace
          flash.now[:error] = 'There has been an error, try again or contact support.'
        end
      end
    else
      @withdraw = @current_user.crypto_withdraws.new
    end
  end

  # for withdraws only
  def cancel
    withdraw = CryptoWithdraw.find params[:id]
    if withdraw and withdraw.user == @current_user
      withdraw.cancel
      redirect_to :panel_wallet, flash: {success: 'Your withdraw has been canceled.'}
    else
      raise CanCan::AccessDenied
    end
  end

end
