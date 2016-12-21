class UsersController < ApplicationController

  layout 'simple'
  
  before_action :login_disallowed, except: [:logout, :mfa]

  def new
  end

  def create
    @current_user = User.new user_params
    if @current_user.save
      session[:user_id] = @current_user.id
      send_email_verification_mailer
      redirect_to :thanks
    else
      error = @current_user.errors['email_addresses.email'].first
      if error == 'Invalid Email Address'
        flash.now[:error] = 'Hmmm, that email looks funny, try again.'
      elsif error == 'Email Already Exists'
        email = EmailAddress.find_by email: @current_user.email_addresses.first.email
        if email.verified?
          flash.now[:error] = 'It looks like you have already signed up. You should <a href="'+login_path+'">login</a> or <a href="'+recover_path+'">recover your password</a>.'
        else
          session[:user_id] = email.user.id
          flash.now[:error] = 'It looks like you have already signed up but forgot to verify your email address.<br><a href="'+resend_path+'">Click here</a> if you need us to send another email verification request.'
        end
      else
        # TODO: should never get here or some other new error was introduced
        raise "Should never get here"
      end
      render :new
    end
  end

  def thanks
    redirect_to :root if !@current_user
  end

  def verify
    email = EmailAddress.find_by email: params[:email]
    if !email
      # Getting here means they tampered with the email
      reset_session
      flash[:error] = 'Something went wrong. You should have us send another email verification request.'
      redirect_to :resend
    elsif email.verified?
      flash[:success] = 'Your Email address is verified. Thank you.'
      if email.user.password?
        redirect_to :login
      else
        session[:user_id] = email.user.id
        redirect_to :continue
      end
    elsif SCrypt::Password.new(email.verification_code) == params[:code]
      now = Time.now
      email.update_attributes verified_at: now, primary_at: now
      flash[:success] = 'Thank you for verifying your email address.'
      session[:user_id] = email.user.id
      redirect_to :continue
    else
      # Getting here means they tampered with the verification code
      reset_session
      flash[:error] = 'Something went wrong. You should have us send another email verification request.'
      redirect_to :resend
    end
  end

  def resend
    if request.post?
      email = EmailAddress.find_by email: params[:resend][:email]
      if email
        session[:user_id] = email.user.id
        redirect_to :resend
      else
        flash.now[:error] = 'Hmmm, couldn\'t find that email address. Have you <a href="'+signup_path+'">signed up</a>?'
      end
    else
      if @current_user 
        send_email_verification_mailer
      else
        flash.now[:error] = 'There\'s been an error, please try again.'
      end
    end
  end

  def recover
    if request.post?
      email = EmailAddress.find_by email: params[:recover][:email]
      if !email
        flash.now[:error] = 'Hmmm, couldn\'t find that email address. Have you <a href="'+signup_path+'">signed up</a>?'
      else
        @current_user = email.user
        session[:user_id] = @current_user.id
        if !@current_user.verified?
          flash.now[:error] = 'You have not verified your email address.<br>Check your email and click the verification link to continue.<br><a href="'+resend_path+'">Click here</a> if you need us to send another email verification request.'
        elsif !@current_user.password? 
          flash.now[:error] = 'You have not set a password.<br>Check your email and click the verification link to continue.<br><a href="'+resend_path+'">Click here</a> if you need us to send another email verification request.'
        else
          send_password_recovery_mailer
        end
      end
    else
      # reset the user_id if loaded
      session[:user_id] = nil
    end
  end

  def reset
    if request.patch?
      if !@current_user
        flash[:error] = 'Something went wrong. You should have us send another password recovery request.'
        redirect_to :recover
      else
        if params[:user][:password].blank? or params[:user][:password_confirmation].blank?
          flash.now[:error] = 'All fields are required, complete the form and try again.'
        elsif params[:user][:password] != params[:user][:password_confirmation]
          flash.now[:error] = 'Your passwords do not match.'
        elsif @current_user.update user_params
          session[:authed] = true
          redirect_to session[:redirect] ? session[:redirect] : :panel_dashboard
        else
          # some strange error, shouldn't get here
        end
      end
    else
      email = EmailAddress.find_by email: params[:email]
      if !email
        # Getting here means they tampered with the email
        reset_session
        flash[:error] = 'Something went wrong. You should have us send another password recovery request.'
        redirect_to :recover
      elsif !params[:code].blank? and SCrypt::Password.new(email.user.password_reset_code) == params[:code]
        @current_user = email.user
        session[:user_id] = @current_user.id
      else
        # getting here means they tampered with the code
        reset_session
        flash[:error] = 'Something went wrong. You should have us send another password recovery request.'
        redirect_to :recover
      end
    end
  end

  def continue
    redirect_to :root if(!@current_user or (@current_user.email and !@current_user.email.verified?))
    if request.patch?
      begin
        birth_date = (!params[:user][:birth_date].blank? ? Time.strptime(params[:user][:birth_date], "%m/%d/%Y") : 18.years.ago)
      rescue
        return flash.now[:error] = 'Your birth date must be in the format of mm/dd/yyyy.'
      end
      @current_user.first_name = params[:user][:first_name]
      @current_user.last_name = params[:user][:last_name]
      @current_user.birth_date = birth_date
      if params[:user][:tos_agreed_at] == '1'
        params[:user][:tos_agreed_at] = Time.now
      else
        return flash.now[:error] = 'You must agree to our terms and conditions.'
      end
      return flash.now[:error] = 'You must be 18 years of age.' if birth_date > 18.years.ago
      any_blank = (params[:user][:first_name].blank? or 
                  params[:user][:last_name].blank? or 
                  params[:user][:password].blank? or
                  params[:user][:password_confirmation].blank?)
      if !any_blank and @current_user.update user_params
        session[:authed] = true
        redirect_to :panel_dashboard
      else
        if params[:user][:password] != params[:user][:password_confirmation]
          flash.now[:error] = 'Your passwords do not match.'
        elsif @current_user.errors[:password] and !@current_user.errors[:password].blank?
          flash.now[:error] = 'Password ' + @current_user.errors[:password].first
        else
          flash.now[:error] = 'All fields are required, complete the form and try again.'
        end
      end
    end
  end

  def login
    if request.post?
      email = EmailAddress.find_by email: params[:login][:email]
      if !email
        flash.now[:error] = 'Hmmm, couldn\'t find that email address. Have you <a href="'+signup_path+'">signed up</a>?'
      else
        @current_user = email.user
        if !email.verified?
          email.session_histories.create! user: @current_user, status: :unverified, ip_address: request.remote_ip
          if @current_user.email_addresses.length <= 1
            session[:user_id] = @current_user.id
            flash.now[:error] = 'You have not verified your email address.<br><a href="'+resend_path+'">Click here</a> if you need us to send another email verification request.'
          else
            flash.now[:error] = 'You have not verified this email address.<br>Login with your primary email address and verify this one so you can use it next time.'
          end
        elsif !@current_user.password? 
          email.session_histories.create! user: @current_user, status: :unverified, ip_address: request.remote_ip
          session[:user_id] = @current_user.id
          flash.now[:error] = 'You have not set a password.<br>Check your email and click the verification link to continue.<br><a href="'+resend_path+'">Click here</a> if you need us to send another email verification request.'
        elsif session[:failed_login_attempts] and session[:failed_login_attempts] >= 3 and !verify_recaptcha
          email.session_histories.create! user: @current_user, status: :captcha_failure, ip_address: request.remote_ip
          flash.now[:error] = 'Your captcha is wrong, try again.'
        elsif !@current_user.passwd? params[:login][:password]
          email.session_histories.create! user: @current_user, status: :password_failure, ip_address: request.remote_ip
          flash.now[:error] = 'Your password is wrong, try again.'
          session[:failed_login_attempts] = session[:failed_login_attempts] ? session[:failed_login_attempts] + 1 : 1
        else
          email.session_histories.create! user: @current_user, status: :success, ip_address: request.remote_ip
          session.delete :failed_login_attempts
          session[:user_id] = @current_user.id
          session[:authed] = true
          if @current_user.mfa_secret
            redirect_to :mfa
          else
            redirect_to session[:redirect] ? session[:redirect] : :panel_dashboard
          end
        end
      end
    end
  end

  def mfa
    if request.post?
      if @current_user.mfa? params[:mfa][:code]
        session.delete :mfa_setup
        session[:mfa_authed] = true
        redirect_to session[:redirect] ? session[:redirect] : :panel_dashboard
      else
        flash.now[:error] = 'Wrong code, try again.'
      end
    end
  end

  def logout
    reset_session
    #flash[:success] = 'You have been logged out.'
    redirect_to :root
  end

private

  def user_params
    params.require(:user).permit(:first_name,
                                 :last_name,
                                 :password,
                                 :password_confirmation,
                                 :country_residence,
                                 :country_citizenship,
                                 :tos_agreed_at,
                                 email_addresses_attributes: [:email])
  end

  def send_email_verification_mailer
    UserMailer.delay(queue: :mailer).email_verification(@current_user.email.id)
  end

  def send_password_recovery_mailer
    UserMailer.delay(queue: :mailer).password_recovery(@current_user.id)
  end
end
