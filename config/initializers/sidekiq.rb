Sidekiq::Queue['trading'].limit = 1
Sidekiq::Queue['trading'].process_limit = 1

class Sidekiq::AuthConstraint
  def self.admin? request
    return false unless request.session['user_id'] and request.session['authed']
    u = User.find request.session['user_id']
    u ? u.admin? : false
  end
end

Sidekiq.configure_server do |config|
  config.redis = {url: 'redis://localhost:6379'}
end

Sidekiq.configure_client do |config|
  config.redis = {url: 'redis://localhost:6379'}
end
