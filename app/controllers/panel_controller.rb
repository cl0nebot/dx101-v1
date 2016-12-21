class PanelController < ApplicationController
  
  force_ssl
  layout 'panel'

  before_action :login_required

end
