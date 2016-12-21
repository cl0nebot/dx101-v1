class CryptoDepositTransactor

  def initialize currency, txid
    @unconfirmed = []
    @currency = currency.to_sym
    @client = CryptoTransactor.new @currency
    @txid = txid
    begin
      @tx = @client.transaction @txid
    rescue Bitcoin::Errors::RPCError => e
      # do nothing, this transaction doesn't exist in our wallet?
    rescue Errno::ETIMEDOUT => e
      raise "#{@currency.to_s.upcase} Server Down"
    end
    @hot_address = ENV["#{currency.to_s}_hot"]
    @cold_address = ENV["#{currency.to_s}_cold"]
    @retry_phases = [10.minutes, 30.minutes, 1.hour, 12.hours, 1.day]
    @any_deposits = false
  end

  def self.receive currency, txid
    transactor = CryptoDepositTransactor.new currency, txid
    transactor.receive
  end

  def receive
    valid_tx? ? process_all : mark_as_malleable
  end

  def self.scheduled? currency, txid
    Sidekiq::Queue.new(:crypto_deposit).to_a.any?{|j| j['queue'] == 'crypto_deposit' and j['args'] == [currency.to_s.downcase, txid]}
  end

private

  def process_all
    process_deposits
    reschedule_deposits
    log_transaction unless @any_deposits
  end

  def process_deposits
    parse_and_merge_deposits_by_address.each do |d|
      address = CryptoAddress.get d[:address]
      if valid_address?(address)
        @any_deposits = true
        deposit = address.crypto_deposits.find_by txid: @txid
        deposit = address.crypto_deposits.new txid: @txid unless deposit
        deposit.with_lock do
          deposit.amount = d[:amount]
          deposit.save!
        end
        process_deposit deposit
      end
    end
  end

  def process_deposit deposit
    deposit.pending? and confirm_deposit?(deposit) ? complete_deposit(deposit) : reschedule_deposit(deposit)
  end

  def parse_and_merge_deposits_by_address
    deposits = []
    @tx['details'].select{|d| d['category'] == 'receive'}
                  .group_by{|d| d['address']}
                  .each do |k,g|
                    amount = BigDecimal.new 0
                    g.each do |d|
                      amount += BigDecimal.new(d['amount'].to_s).abs
                    end
                    deposits << {
                      address: k,
                      amount: amount
                    }
                  end
    deposits
  end

  def valid_tx?
    @tx and @tx['details']
  end

  def valid_address? address
    address and address.address != @hot_address
  end

  def confirm_deposit? deposit
    # TODO: this will be more advanced later based on the deposit amount / user's history and age and network hash rate
    ((@currency == :xbt and @tx['confirmations'] >= 6) or @tx['confirmations'] >= 20)
  end

  def complete_deposit deposit
    deposit.with_lock do
      deposit.update_attributes! status: :complete, confirmations: @tx['confirmations'], complete_at: Time.now
      deposit.user.add_funding deposit.amount, deposit
    end
  end

  def reschedule_deposit deposit
    @unconfirmed << deposit
  end

  def reschedule_deposits
    unless @unconfirmed.blank?
      if @unconfirmed.first.retries < 4
        CryptoDepositWorker.perform_in @retry_phases[@unconfirmed.first.retries], @currency, @txid unless scheduled?
        @unconfirmed.each do |deposit|
          deposit.with_lock do
            deposit.update_attributes! confirmations: @tx['confirmations'], retries: (deposit.retries + 1)
          end
        end
      else
        @unconfirmed.each do |deposit|
          deposit.with_lock do
            deposit.update_attributes! status: :unconfirmed, canceled_at: Time.now
          end
        end
      end
    end
  end
  
  def scheduled?
    CryptoDepositTransactor.scheduled? @currency, @txid
  end

  def mark_as_malleable
    deposits = CryptoDeposit.where txid: @txid
    deposits.each do |deposit|
      deposit.with_lock do
        deposit.user.remove_funding deposit.amount, deposit if deposit.complete?
        deposit.update_attributes! status: :malleable, canceled_at: Time.now
      end
    end
  end

  def log_transaction
    Logger.new("#{Rails.root}/log/no_address_for_tx.log").info({currency: @currency, txid: @txid}.to_json)
  end

end
