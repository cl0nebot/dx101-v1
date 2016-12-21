class AdminController < ApplicationController
  
  force_ssl
  layout 'admin'

  before_action :admin_required

  def admin_required
    if !authed? or (@current_user and !@current_user.admin?)
      flash[:error] = 'Login to access that page.'
      session[:redirect] = request.fullpath
      redirect_to :login 
    end
  end

end
