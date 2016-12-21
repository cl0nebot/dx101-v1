class TradeTransactionInvert

  require 'money'

  attr_reader :rate_currency, :quantity_currency, :quantity, :rate, :rate_subunit, :price, :price_subunit, :quantity_subunit, :created_at

  def initialize transaction
    @quantity_currency = transaction.rate_currency
    @rate_currency = transaction.quantity_currency
    @quantity = transaction.price
    @rate = Money.new(BigDecimal.new(1)/transaction.rate.amount*transaction.quantity.currency.subunit_to_unit, @rate_currency)
    @price = transaction.quantity
    @created_at = transaction.created_at
  end

end
