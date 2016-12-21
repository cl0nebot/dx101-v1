class Panel::AccountController < PanelController

  before_action :validate_password, only: [:update]

  def show
    params[:user] = @current_user
  end

  def update
    if @current_user.update user_params
      flash[:success] = 'You have succesfully updated your account.'
    else
      if params[:user][:password] != params[:user][:password_confirmation]
        flash[:error] = 'Your passwords do not match.'
      elsif @current_user.errors[:password] and !@current_user.errors[:password].blank?
        flash[:error] = 'Password ' + @current_user.errors[:password].first
      else
        flash[:error] = 'All fields are required, complete the form and try again.'
      end
    end
    redirect_to :panel_account
  end

  def enable_mfa
    if @current_user.mfa_secret
      redirect_to :panel_account
    else
      @current_user.generate_mfa_secret
      session[:mfa_setup] = true
      redirect_to :mfa
    end
  end

  def disable_mfa
    @current_user.update_attribute :mfa_secret, nil
    redirect_to :panel_account, flash: {success: 'Google authenticator has been disabled.'}
  end

private

  def user_params
    params.require(:user).permit(:first_name,
                                 :last_name,
                                 :password,
                                 :password_confirmation,
                                 :country_residence,
                                 :country_citizenship,
                                 email_addresses_attributes: [:email])
  end

  def validate_password
    redirect_to :panel_account, flash: {error: 'Your current password is invalid'} if params[:user][:password_current] and !@current_user.passwd?(params[:user][:password_current])
  end

end
