class CryptoWithdraw < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  belongs_to :crypto_withdraw_batch
  has_many :finance_transactions, as: :related, class_name: 'Finance::Transaction'
  validates :user, presence: true
  validates :address, presence: true
  validates :currency, presence: true
  validates :amount_subunit, presence: true, numericality: {greater_than: 0}
  validate :address_exists
  monetize :amount_subunit, as: 'amount', with_model_currency: :currency
  monetize :fee_subunit, as: 'fee', with_model_currency: :currency
  enum status: {
    pending: 0,
    processing: 1,
    complete: 2,
    canceled: 3
  }
  after_initialize :setup
  after_create :hold_funds, :notify_chat

  Finance.crypto_currencies.each do |c|
    scope c, -> {where currency: c.to_s}
  end

  def cancel
    if pending? or processing?
      ActiveRecord::Base.transaction do
        update_attributes! status: :canceled, canceled_at: Time.now
        user.move_funds_for_withdraw_cancellation amount + fee, self
      end
    end
  end

private
  
  def setup
    # TODO: Make this go into a pending state for manual approval based on the amount being withdrawn
    self.status ||= :processing
  end

  def address_exists
    errors[:address] << 'is not valid.' unless CryptoTransactor.validate_address(currency, address)['isvalid']
  end

  def hold_funds
    user.move_funds_for_withdraw amount + fee, self
  end

  def notify_chat
    ChatTransactor.notify 'Dev', "Withdraw#{' [Dev]' if Rails.env.development?}", "There has been a withdraw requested in the amount of #{currency.upcase} #{amount.round}", {notify: true}
  end

end
