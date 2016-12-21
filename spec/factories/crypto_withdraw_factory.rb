FactoryGirl.define do

  factory :crypto_withdraw do
    rich_user
    status :processing
    currency 'XBT'
    address 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
    amount_subunit 100000000
    fee_subunit 200000
  end

end
