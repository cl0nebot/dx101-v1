class CryptoWithdrawTransactor

  attr_accessor :errors

  def self.batch ids
    errors = {}
    grouped_withdraws = CryptoWithdraw.includes(:user).processing.where(id: ids).group_by &:currency
    grouped_withdraws.each do |currency, withdraws|
      w = CryptoWithdrawTransactor.withdraw currency, withdraws
      errors[currency] = w.errors unless w.errors.blank?
    end
    ChatTransactor.notify 'Dev', "Withdraw#{' [Dev]' if Rails.env.development?}", "There has been an error with the last batched withdraw.", {notify: true, color: 'red'} unless errors.blank?
    errors
  end

  def self.withdraw currency, withdraws
    transactor = CryptoWithdrawTransactor.new currency, withdraws
    transactor.withdraw
  end

  def initialize currency, withdraws
    @currency = currency
    @withdraws = withdraws
    @ids = @withdraws.map(&:id)
    @total = Money.new 0, currency
    @total_fees = Money.new 0, currency
    @network_fee = nil
    @revenue = nil
    @addresses_amounts = {}
    @debits = []
    @credits = []
    @batch = CryptoWithdrawBatch.create! currency: currency
    @txid = nil
    @tx = nil
    @transaction = nil
    @withdraws.each do |w|
      @total += w.amount
      @total_fees += w.fee
      @addresses_amounts[w.address] = @addresses_amounts[w.address] ? @addresses_amounts[w.address] + w.amount : w.amount
      @debits << {account: w.user.find_account(:liability, :user_withdraw_holdings), amount: (w.amount + w.fee)}
      @credits << {account: w.user.find_account(:revenue, :user_withdraw_sales), amount: w.fee}
    end
    @addresses_amounts.each do |address, amount|
      @addresses_amounts[address] = amount.to_f
    end
    @errors = []
  end

  def withdraw
    begin
      mark_as_complete
      send_transaction
      find_transaction
      update_batch
      create_finance_transaction
    rescue => e
      @errors << e.to_s
      log_everything
    end
    self
  end

private

  def mark_as_complete
    begin
      ActiveRecord::Base.transaction do
        t = Time.now
        @withdraws.each do |w|
          w.update_attributes! crypto_withdraw_batch: @batch, status: :complete, complete_at: t
        end
      end
    rescue => e
      @errors << e.to_s
      raise 'Could not mark withdraws as complete'
    end
  end

  def mark_as_uncomplete
    begin
      ActiveRecord::Base.transaction do
        t = Time.now
        @withdraws.each do |w|
          w.update_attributes! crypto_withdraw_batch: nil, status: :processing, complete_at: nil
        end
      end
    rescue => e
      @errors << e.to_s
      raise 'Could not mark withdraws as uncomplete'
    end
  end

  def destroy_batch
    begin 
      @batch.destroy
    rescue => e
      @errors << e.to_s
      raise 'Could not destroy batch'
    end
  end

  def send_transaction
    begin
      @txid = CryptoTransactor.send_many @currency, @addresses_amounts, "Batch ID: #{@batch.id}"
    rescue => e
      @errors << e.to_s
      mark_as_uncomplete
      destroy_batch
      raise 'Could not complete transaction'
    end
  end

  def find_transaction
    begin
      @tx = CryptoTransactor.transaction @currency, @txid
    rescue => e
      @errors << e.to_s
      raise 'Could not find transaction'
    end
  end

  def update_batch
    if @tx and @tx['fee']
      @network_fee =  BigDecimal.new(@tx['fee'].to_s).abs
      begin
        @batch.update_attributes! txid: @txid, fee: @network_fee
      rescue => e
        @errors << e.to_s
        raise 'Could not update batch'
      end
    else
      raise 'Could not parse transaction details and fee'
    end
  end

  def create_finance_transaction
    begin
      hot = Finance::Asset.find_by name: 'Hot'
      withdraw_fees = Finance::Expense.find_by name: 'Withdraw Fees'
      @debits << {account: withdraw_fees, amount: @batch.fee}
      @credits << {account: hot, amount: (@total + @batch.fee)}
      @transaction = Finance::Transaction.build(
        related: @batch,
        transaction_type: :withdraw,
        debits: @debits,
        credits: @credits
      )
      @transaction.save!
    rescue => e
      @errors << e.to_s
      raise 'Could not create finance transaction'
    end
  end

  def log_everything
    Logger.new("#{Rails.root}/log/withdraw_failures.log").info({
      errors: @errors,
      currency: @currency,
      withdraw_ids: @ids,
      batch_id: @batch.id,
      txid: @txid
    }.to_json)
  end

end
