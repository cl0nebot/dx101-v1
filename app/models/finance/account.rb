class Finance::Account < ActiveRecord::Base

  has_many :credit_amounts, extend: Finance::AmountsExtension
  has_many :debit_amounts, extend: Finance::AmountsExtension
  has_many :credit_transactions, through: :credit_amounts, source: :finance_transaction
  has_many :debit_transactions, through: :debit_amounts, source: :finance_transaction
  belongs_to :user
  validates_presence_of :type
  validates_uniqueness_of :name, unless: 'name.blank?'
  enum category: {
    user_liability: 0,
    user_mu_sales: 1,
    user_trade_holdings: 2,
    user_transaction_sales: 3,
    user_withdraw_holdings: 4,
    user_withdraw_sales: 5
  }

  def credits_balance(currencies = nil)
    credit_amounts.balance currencies
  end

  def debits_balance(currencies = nil)
    debit_amounts.balance currencies
  end

  def self.balance(currencies = nil, query = nil)
    if [Finance::Account, Finance::DebitNormalBalanceAccount, Finance::CreditNormalBalanceAccount].include? self.new.class
      raise(NoMethodError, "undefined method 'balance'")
    else
      currency_balances = Finance.build_currency_balances currencies
      query[:category] = Finance::Account.categories[query[:category].to_sym] if query[:category]
      accounts = self.where query
      accounts.each do |a|
        b = a.balance
        currency_balances.each do |k,v|
          if b.key? k.to_sym
            unless a.contra
              currency_balances[k] += b[k]
            else
              currency_balances[k] -= b[k]
            end
          end
        end
      end
      currency_balances
    end
  end

  # TODO rewrite this to work with currencies
  def self.trial_balance
    unless self.new.class == Finance::Account
      raise(NoMethodError, "undefined method 'trial_balance'")
    else
      Finance::Asset.balance - (Finance::Liability.balance + Finance::Equity.balance + Finance::Revenue.balance - Finance::Expense.balance)
    end
  end

end
