module OptionsForSelectHelper

  def options_for_crypto_types selected, show_all = true
    options = []
    options << ['All', nil] if show_all
    Finance.crypto_names.each do |n|
      options << [n, Finance.crypto_currency_by_name(n)]
    end
    options_for_select options, selected: selected
  end

  def options_for_crypto_currencies selected, show_all = true
    options = []
    options << ['All', nil] if show_all
    Finance.crypto_currencies.each do |c|
      options << [c.upcase, c]
    end
    options_for_select options, selected
  end

  def options_for_crypto_names selected, show_all = true
    options = []
    options << ['All', nil] if show_all
    Finance.crypto_names.each do |n|
      options << [n, Finance.crypto_currency_by_name(n)]
    end
    options_for_select options, selected
  end

end
