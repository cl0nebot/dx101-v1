require 'spec_helper'

describe CryptoWithdrawTransactor do

  before :each do
    @user = create :rich_user
  end

  describe 'withdraw' do
    it 'should process and pay withdraws and merge withdraws going to the same address' do
      hot = Finance::Asset.find_by name: 'Hot'
      old_xbt_hot_balance = hot.balance[:xbt]
      old_xbt_user_balance = @user.balance[:xbt]
      @w1 = @user.crypto_withdraws.create!(attributes_for(:crypto_withdraw, amount: '.001'))
      @w2 = @user.crypto_withdraws.create!(attributes_for(:crypto_withdraw, amount: '.001'))
      (old_xbt_user_balance - @w1.amount - @w1.fee - @w2.amount - @w2.fee).should == @user.balance[:xbt]
      withdraw_holdings = @user.find_account :liability, :user_withdraw_holdings
      withdraw_holdings.balance[:xbt].should == (@w1.amount + @w1.fee + @w2.amount + @w2.fee)
      CryptoTransactor.stub({
        send_many: 'faa5af2234138634765ae525a035c8aacdc2e6a8c1f34e458498fd549b9d66ca',
        transaction: {'fee' => 0.0001}
      })
      CryptoWithdrawTransactor.withdraw :xbt, [@w1, @w2]
      @w1.complete?.should == true
      @w2.complete?.should == true
      batch = CryptoWithdrawBatch.first
      batch.txid.present?.should == true
      batch.finance_transaction.present?.should == true
      CryptoTransactor.should have_received(:send_many).with(
        :xbt,
        {"#{@w1.address}" => 0.002},
        "Batch ID: #{batch.id}"
      )
      withdraw_holdings.reload
      withdraw_holdings.balance[:xbt].should == 0
      revenue_account = @user.find_account :revenue, :user_withdraw_sales
      revenue_account.balance[:xbt].should == @w1.fee + @w2.fee
      withdraw_fees = Finance::Expense.find_by name: 'Withdraw Fees'
      withdraw_fees.balance[:xbt].should == batch.fee
      hot.reload
      hot.balance[:xbt].should == old_xbt_hot_balance - (@w1.amount + @w2.amount + batch.fee)
    end
  end

end
