FactoryGirl.define do

  factory :trade do
    trade_type :market
    transfer_type :buy
    quantity_currency 'XBT'
    rate_currency 'LTC'
    rate_subunit 0
    stop_subunit 0

    factory :market_buy do
      trade_type :market
      transfer_type :buy
    end

    factory :lmt_buy do
      trade_type :lmt
      transfer_type :buy
    end

    factory :stop_buy do
      trade_type :stop
      transfer_type :buy
    end

    factory :stop_lmt_buy do
      trade_type :stop_lmt
      transfer_type :buy
    end

    factory :market_sell do
      trade_type :market
      transfer_type :sell
    end

    factory :lmt_sell do
      trade_type :lmt
      transfer_type :sell
    end

    factory :stop_sell do
      trade_type :stop
      transfer_type :sell
    end

    factory :stop_lmt_sell do
      trade_type :stop_lmt
      transfer_type :sell
    end
  end

end
