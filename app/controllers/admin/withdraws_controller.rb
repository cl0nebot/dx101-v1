class Admin::WithdrawsController < AdminController

  def index
    @grouped_withdraws = CryptoWithdraw.processing.includes(user: [:email_addresses]).group_by &:currency
  end

  def cancel
    withdraw = CryptoWithdraw.find params[:id]
    withdraw.cancel if withdraw
    redirect_to :admin_withdraws, flash: {success: 'Withdraw canceled'}
  end

  def batch
    begin 
      errors = CryptoWithdrawTransactor.batch params[:ids].split(',')
      if errors.blank?
        redirect_to :admin_withdraws, flash: {success: 'Withdraws have successfully been paid'}
      else
        redirect_to :admin_withdraws, flash: {error: "There has been an error, please have a technician review the log.<br><br> Json Error Report: #{errors.to_json}".html_safe}
      end
    rescue => e
      puts e
      puts e.backtrace
      redirect_to :admin_withdraws, flash: {error: e.to_s}
    end
  end

end
