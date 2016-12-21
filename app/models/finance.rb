module Finance

  def self.table_name_prefix
    'finance_'
  end

  def self.fiat_currencies
    [:usd]
  end

  def self.internal_currencies
    [:smu, :pmu]
  end

  def self.crypto_currencies
    Money::Currency.table.select{|k,v| k if v[:priority] == 300}.keys
  end

  def self.crypto_names
    Money::Currency.table.select{|k,v| k if v[:priority] == 300}.map{|k,v| v[:name]}
  end

  def self.crypto_currency_by_name name
    a = Money::Currency.table.find{|k,v| v[:priority] == 300 and v[:name] == name.to_s.capitalize}
    a.first if a
  end

  def self.crypto_name_by_currency currency
    o = Money::Currency.table[currency.downcase.to_sym]
    o[:name] if o
  end

  def self.currencies
    self.fiat_currencies + self.internal_currencies + self.crypto_currencies
  end

  def self.build_currency_balances currencies
    currency_balances = {}
    currencies = currencies || Finance.currencies
    if currencies.is_a? Array
      currencies.each do |c|
        currency_balances[c] = Money.new 0, c
      end
    else
      currency_balances[currencies.to_sym] = Money.new 0, currencies 
    end
    currency_balances
  end

  def self.subtract_debits_from_credits(debit_balances, credit_balances)
    debit_balances.each do |k,v|
      credit_balances[k] -= v
    end
    credit_balances
  end

  def self.subtract_credits_from_debits(debit_balances, credit_balances)
    credit_balances.each do |k,v|
      debit_balances[k] -= v
    end
    debit_balances
  end

end
