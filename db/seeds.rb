=begin
  w = u.crypto_withdraws.create!(
    currency: 'XBT',
    amount: BigDecimal.new('.5'),
    fee: ENV['xbt_withdraw_fee'],
    address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
  )
  w = u.crypto_withdraws.create!(
    currency: 'XBT',
    amount: BigDecimal.new('.3'),
    fee: ENV['xbt_withdraw_fee'],
    address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
  )

  u.crypto_addresses.create! address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR', currency: :xbt, label: 'Bitcoin Test Addy'
=end
