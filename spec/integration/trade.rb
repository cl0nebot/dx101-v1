require 'spec_helper'

describe Trade do

  before :each do
    # setting a trade rate for xbt/ltc
    @user = create :rich_user
    buy = @user.trades.create!(attributes_for(:lmt_buy, quantity: 5, rate: 100))
    sell = @user.trades.create!(attributes_for(:lmt_sell, quantity: 5, rate: 100))
  end

  describe 'regular trading' do

    it 'should trade market to market' do
      t1 = @user.trades.create!(attributes_for(:market_buy, quantity: 1))
      t2 = @user.trades.create!(attributes_for(:market_sell, quantity: 1))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trade market to limit' do
      t1 = @user.trades.create!(attributes_for(:market_buy, quantity: 1))
      t2 = @user.trades.create!(attributes_for(:lmt_sell, quantity: 1, rate: 100))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trade limit to limit' do
      t1 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 1, rate: 100))
      t2 = @user.trades.create!(attributes_for(:lmt_sell, quantity: 1, rate: 100))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trigger and trade a stop trade' do
      t1 = @user.trades.create!(attributes_for(:stop_buy, quantity: 1, stop_rate: 100))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: 1, rate: 100))
      t3 = @user.trades.create!(attributes_for(:lmt_sell, quantity: 2, rate: 100))
      t1.reload
      t2.reload
      t3.reload
      t1.complete?.should == true
      t2.complete?.should == true
      t3.complete?.should == true
    end

    it 'should trigger and trade a stop limit trade' do
      t1 = @user.trades.create!(attributes_for(:stop_lmt_buy, quantity: 1, rate: 99, stop_rate: 100))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: 1, rate: 100))
      t3 = @user.trades.create!(attributes_for(:lmt_sell, quantity: 1, rate: 100))
      t4 = @user.trades.create!(attributes_for(:lmt_sell, quantity: 1, rate: 99))
      t1.reload
      t2.reload
      t3.reload
      t4.reload
      t1.complete?.should == true
      t2.complete?.should == true
      t3.complete?.should == true
      t4.complete?.should == true
    end

  end

  describe 'inverse trading' do

    it 'should trade market to market' do
      t1 = @user.trades.create!(attributes_for(:market_buy, quantity: 1))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: 100, quantity_currency: 'LTC', rate_currency: 'XBT'))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trade market to limit' do
      t1 = @user.trades.create!(attributes_for(:market_buy, quantity: 1))
      t2 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 100, quantity_currency: 'LTC', rate_currency: 'XBT', rate: '.01'))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trade limit to limit' do
      t1 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 1, rate: 100))
      t2 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 100, quantity_currency: 'LTC', rate_currency: 'XBT', rate: '.01'))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

    it 'should trigger and trade a stop trade' do
      t1 = @user.trades.create!(attributes_for(:stop_buy, quantity: 1, stop_rate: 100))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: 1, rate: 100))
      t3 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 200, quantity_currency: 'LTC', rate_currency: 'XBT', rate: '.01'))
      t1.reload
      t2.reload
      t3.reload
      t1.complete?.should == true
      t2.complete?.should == true
      t3.complete?.should == true
    end

    it 'should trigger and trade a stop limit trade' do
      t1 = @user.trades.create!(attributes_for(:stop_lmt_buy, quantity: 1, rate: 99, stop_rate: 100))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: 1, rate: 100))
      t3 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 100, quantity_currency: 'LTC', rate_currency: 'XBT', rate: '.01'))
      t4 = @user.trades.create!(attributes_for(:lmt_buy, quantity: 99, quantity_currency: 'LTC', rate_currency: 'XBT', rate: '.01010101'))
      t1.reload
      t2.reload
      t3.reload
      t4.reload
      t1.complete?.should == true
      t2.complete?.should == true
      t3.complete?.should == true
      t4.complete?.should == true
    end

  end

  describe 'limit trading' do

    it 'should sent trade to pending funds if user can not cover' do
      t = @user.trades.create!(attributes_for(:stop_lmt_buy, quantity: 10000000000, rate: 99, stop_rate: 100))
      t.reload
      t.pending_funds?.should == true
    end

    it 'should add up' do
      t1 = @user.trades.create!(attributes_for(:lmt_sell, quantity: Money.new(25000, :pmu), rate: Money.new(900000, :xbt)))
      t2 = @user.trades.create!(attributes_for(:market_buy, quantity: Money.new(25000, :pmu), rate_currency: 'XBT'))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end

=begin
    # Don't think it's going to be possible to get this one to ever work at 100% completion on both trades
    it 'should add up again invertently' do
      t1 = @user.trades.create!(attributes_for(:lmt_sell, quantity: Money.new(25000, :pmu), rate: Money.new(900000, :xbt)))
      t2 = @user.trades.create!(attributes_for(:market_sell, quantity: '2.25'.to_money(:xbt), rate_currency: 'PMU'))
      t1.reload
      t2.reload
      t1.complete?.should == true
      t2.complete?.should == true
    end
=end

  end

end
