class CryptoDeposit < ActiveRecord::Base
  
  has_paper_trail meta: {user_id: :user_id}
  belongs_to :crypto_address
  has_many :finance_transactions, as: :related, class_name: 'Finance::Transaction' # one for deposit and one if it gets canceled (rare)
  delegate :user, :currency, :address, to: :crypto_address
  validates :crypto_address, presence: true
  validates :txid, presence: true
  validates :status, presence: true
  monetize :amount_subunit, as: 'amount', with_model_currency: :currency
  enum status: {
    pending: 0,
    processing: 1,
    complete: 2,
    malleable: 3,
    unconfirmed: 4
  }
  after_initialize :setup

  Finance.crypto_currencies.each do |c|
    scope c, -> {joins(:crypto_address).where("crypto_addresses.currency = ?", c.to_s)}
  end

  # scope to use when showing customers their deposits
  scope :viewable, -> {where "status IN (?,?,?)", CryptoDeposit.statuses[:pending], CryptoDeposit.statuses[:processing], CryptoDeposit.statuses[:complete]}
  scope :for_admin, -> {where "status IN (?,?)", CryptoDeposit.statuses[:malleable], CryptoDeposit.statuses[:unconfirmed]}

private

  def setup
    self.status ||= :pending
    self.confirmations ||= 0
    self.retries ||= 0
  end

end
