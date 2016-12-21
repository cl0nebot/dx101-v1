class Finance::Amount < ActiveRecord::Base
  belongs_to :finance_transaction, class_name: 'Finance::Transaction', foreign_key: 'transaction_id'
  belongs_to :account
  validates_presence_of :type, :amount_subunit, :finance_transaction, :account, :currency
  monetize :amount_subunit, as: 'amount', with_model_currency: :currency
end
