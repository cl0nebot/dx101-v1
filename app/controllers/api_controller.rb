class ApiController < ActionController::Base

  force_ssl

private

  def auth_required
    authenticate_or_request_with_http_basic do |username, password|
      currency = params[:currency]
      username == ENV["#{currency}_user"] and password == ENV["#{currency}_pass"] if currency
    end
  end

end
