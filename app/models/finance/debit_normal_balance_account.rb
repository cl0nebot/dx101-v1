class Finance::DebitNormalBalanceAccount < Finance::Account

  def balance(currencies = nil)
    unless contra
      Finance.subtract_credits_from_debits debits_balance(currencies), credits_balance(currencies) 
    else
      Finance.subtract_debits_from_credits debits_balance(currencies), credits_balance(currencies) 
    end
  end

end
