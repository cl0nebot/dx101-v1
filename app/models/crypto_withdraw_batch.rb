class CryptoWithdrawBatch < ActiveRecord::Base

  has_paper_trail
  has_many :crypto_withdraws
  has_one :finance_transaction, as: :related, class_name: 'Finance::Transaction'
  validates :txid, presence: true, if: :fee_subunit?
  validates :currency, presence: true
  validates :fee_subunit, presence: true, if: :txid?
  monetize :fee_subunit, as: 'fee', with_model_currency: :currency, allow_nil: true

  Finance.crypto_currencies.each do |c|
    scope c, -> {where currency: c.to_s}
  end

end
