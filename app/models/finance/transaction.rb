class Finance::Transaction < ActiveRecord::Base

  belongs_to :related, polymorphic: true
  has_many :credit_amounts, extend: Finance::AmountsExtension
  has_many :debit_amounts, extend: Finance::AmountsExtension
  has_many :credit_accounts, through: :credit_amounts, source: :account
  has_many :debit_accounts, through: :debit_amounts, source: :account
  validate :has_credit_amounts?
  validate :has_debit_amounts?
  validate :amounts_cancel?
  enum transaction_type: {
    deposit: 0, 
    deposit_cancellation: 1, 
    pmu_purchase: 2,
    smu_purchase: 3, 
    trade: 4, 
    trade_cancellation: 5,
    trade_holding: 6, 
    withdraw: 7, 
    withdraw_holding: 8, 
    withdraw_cancellation: 9
  }

  def self.build(hash)
    transaction = Finance::Transaction.new(transaction_type: hash[:transaction_type]||nil, related: hash[:related])
    hash[:debits].each do |debit|
      a = debit[:account].class == String ? Account.find_by_name(debit[:account]) : debit[:account]
      transaction.debit_amounts << Finance::DebitAmount.new(account: a, amount: debit[:amount], finance_transaction: transaction)
    end
    hash[:credits].each do |credit|
      a = credit[:account].class == String ? Account.find_by_name(credit[:account]) : credit[:account]
      transaction.credit_amounts << Finance::CreditAmount.new(account: a, amount: credit[:amount], finance_transaction: transaction)
    end
    transaction
  end

  def accounts
    self.credit_accounts + self.debit_accounts
  end

private
  def has_credit_amounts?
    errors[:base] << "Transaction must have at least one credit amount" if self.credit_amounts.blank?
  end

  def has_debit_amounts?
    errors[:base] << "Transaction must have at least one debit amount" if self.debit_amounts.blank?
  end

  def amounts_cancel?
    errors[:base] << "The credit and debit amounts are not equal" if credit_amounts.balance != debit_amounts.balance
  end

end
