class CryptoAddress < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  has_many :crypto_deposits
  validates :user, presence: true
  validates :address, presence: true, uniqueness: true
  validates :currency, presence: true
  scope :hidden, -> {where 'hide_at is not null'}
  scope :visible, -> {where 'hide_at is null'}
  after_initialize :setup

  Finance.crypto_currencies.each do |c|
    scope c, -> {where currency: c.to_s}
  end

  def self.get(address)
    self.find_by address: address
  end

  def get(address)
    self.find_by address: address
  end

  def hide
    self.update_attribute :hide_at, Time.now
  end

  def show
    self.update_attribute :hide_at, nil
  end

  def hidden?
    self.hide_at?
  end

  def qr_uri size="200x200"
    GoogleQR.new(data: address, size: size).to_s
  end

private

  def setup
    self.address ||= CryptoTransactor.new_address self.currency if self.currency
  end

end
