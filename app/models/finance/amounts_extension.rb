module Finance
  module AmountsExtension
    def balance(currencies = nil)
      currency_balances = Finance.build_currency_balances currencies
      each do |r|
        c = r.currency.downcase.to_sym
        currency_balances[c] += r.amount if currency_balances.key? c and r.amount_subunit
      end
      currency_balances
    end
  end
end
