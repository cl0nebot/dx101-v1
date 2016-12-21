module NumberHelper

  def fmt_us_number(number)
    digits = number.gsub(/\D/, '').split(//)
    digits.shift if digits.length == 11 and digits[0] == '1'
    "(#{digits[0,3].join()}) #{digits[3,3].join()}-#{digits[6,4].join()}" if digits.length == 10
  end

end
