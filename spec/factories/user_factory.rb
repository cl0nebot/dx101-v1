FactoryGirl.define do

  factory :user do
    first_name 'Larron'
    last_name 'Armstead'
    password 'testP@ss'
    password_confirmation {password}
    factory :agent do

    end
    factory :admin do

    end
    factory :rich_user do
      after :create do |user, evaluator|
        (Finance.crypto_currencies + [:pmu, :smu]).each do |c|
          user.add_funding Money.new(10000000000000, c)
        end
      end
    end
  end

end
