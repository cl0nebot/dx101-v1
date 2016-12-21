class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :exception

  before_action :load_current_user 
  before_action :timeout

  rescue_from CanCan::AccessDenied do |exception|
    #render file: "#{Rails.root}/public/403.html", :status => 403, :layout => false
    redirect_to (authed? ? :panel_dashboard : root), error: "You don't have access to that page"
  end

private

  def load_current_user
    @current_user = User.find session[:user_id] if session[:user_id]
  end

  def current_user
    @current_user
  end

  def timeout
    s = Session.find_by session_id: session.id
    if authed? and s and s.updated_at < 10.minute.ago and !Rails.env.development?
      reset_session
      flash[:error] = 'Login to access that page.'
      session[:redirect] = request.fullpath unless request.fullpath.match 'ping'
      return redirect_to :login 
    elsif authed? and s
      s.update_attribute :updated_at, Time.now
    end
  end

  def authed?
    !!session[:authed]
  end

  def mfa_authed?
    !!session[:mfa_authed]
  end

  def login_required
    unless authed?
      flash[:error] = 'Login to access that page.'
      session[:redirect] = request.fullpath
      return redirect_to :login 
    end
    mfa_required unless session[:mfa_setup] and params[:action] == 'disable_mfa'
  end

  def mfa_required
    check_mfa if authed? and @current_user and @current_user.mfa_secret
  end

  def check_mfa
    unless mfa_authed?
      flash[:error] = 'Google auth required to access that page.'
      session[:redirect] = request.fullpath
      redirect_to :mfa 
    end
  end

  def login_disallowed
    redirect_to :panel_dashboard if authed?
  end

  def user_for_paper_trail
    session[:user_id]
  end

  def info_for_paper_trail
    {
      :ip_address => request.remote_ip,
      :user_agent => request.user_agent
    }
  end

  def append_info_to_payload(payload)
    super
    payload[:params] = request.filtered_parameters
    payload[:ip_address] = request.remote_ip
    payload[:user_agent] = request.user_agent
  end

end
