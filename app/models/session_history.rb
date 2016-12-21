class SessionHistory < ActiveRecord::Base

  belongs_to :user
  belongs_to :related, polymorphic: true
  validates :user, presence: true
  validates :related, presence: true
  validates :status, presence: true
  validates :ip_address, presence: true
  enum status: {
    captcha_failure: 0,
    password_failure: 1,
    success: 2,
    unverified: 3
  }
  after_create :fail2ban_log

private

  def fail2ban_log
    Logger.new("#{Rails.root}/log/fail2ban.log").info "password_failure #{ip_address} #{user.id}" if password_failure?
  end

end
