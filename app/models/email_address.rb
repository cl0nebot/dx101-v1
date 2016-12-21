class EmailAddress < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  has_many :session_histories, as: :related
  validates :email, uniqueness: {case_sensitive: false, message: 'Email Already Exists'}, presence: true, format: {with: /@/, message: 'Invalid Email Address'}
  scope :primary, -> {where 'primary_at is not null'}
  scope :verified, -> {where 'verified_at is not null'}

  def generate_verification_code
    code = SecureRandom.hex(8)
    self.update_attribute :verification_code, SCrypt::Password.create(code)
    code
  end

  def verify_email
    self.update_attribute :verified_at, Time.now
  end

  def set_as_primary
    self.demote_primary_sibling
    self.update_attribute :primary_at, Time.now
  end

  def demote_primary_sibling
    unless self.user.email_addresses.primary.blank?
      current = self.user.email_addresses.primary.first
      current.update_attribute :primary_at, nil 
    end
  end

  def verified?
    self.verified_at?
  end

  def primary?
    self.primary_at?
  end

end
