FactoryGirl.define do
  
  factory :crypto_address do
    user
    factory :bitcoin_address do
      currency 'XBT'
    end
  end

end
