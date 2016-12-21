require 'spec_helper'

describe CryptoDepositTransactor do
  
  before :each do
    CryptoTransactor = double :crypto_transactor
    CryptoTransactor.stub new: CryptoTransactor
    CryptoDepositWorker.stub perform_in: nil
  end

  describe 'receive' do

    it 'should gracefully process a bad tx' do
      CryptoTransactor.stub(transaction: 'somin')
      CryptoDepositTransactor.receive :xbt, 'txid'
    end

    it 'should mark unconfirmed malleable tx deposits' do
      address = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 0,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      address.crypto_deposits.length.should == 1
      unconfirmed_deposit = address.crypto_deposits.first
      unconfirmed_deposit.txid.should == '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      unconfirmed_deposit.amount.should == Money.new(170000000, :xbt)
      unconfirmed_deposit.pending?.should == true
      address.user.balance[:xbt].should == Money.new(0, :xbt)
      CryptoTransactor.stub(transaction: nil)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      unconfirmed_deposit.reload
      unconfirmed_deposit.malleable?.should == true
    end

    it 'should cancel confirmed malleable tx deposits and remove balance' do
      address = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      address.crypto_deposits.length.should == 1
      confirmed_deposit = address.crypto_deposits.first
      confirmed_deposit.txid.should == '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      confirmed_deposit.amount.should == Money.new(170000000, :xbt)
      confirmed_deposit.complete?.should == true
      address.user.balance[:xbt].should == Money.new(170000000, :xbt)
      CryptoTransactor.stub(transaction: nil)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      confirmed_deposit.reload
      confirmed_deposit.malleable?.should == true
      confirmed_deposit.finance_transactions.length.should == 2
      address.user.balance[:xbt].should == Money.new(0, :xbt)
    end

    it 'should ignore deposits for receiving addresses not in our system' do
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      CryptoDeposit.count.should == 0
    end

    it 'should process a legitimate tx' do
      address = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit = address.crypto_deposits.first
      deposit.amount.should == Money.new(170000000, :xbt)
      deposit.complete?.should == true
    end

    it 'should process a legitimate tx with multiple receiving addresses in our system' do
      address1 = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      address2 = create :bitcoin_address, address: 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          },
          {
            'category' => 'receive',
            'address' => 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4',
            'amount' => 0.30000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1 = address1.crypto_deposits.first
      deposit1.amount.should == Money.new(170000000, :xbt)
      deposit1.complete?.should == true
      deposit2 = address2.crypto_deposits.first
      deposit2.amount.should == Money.new(30000000, :xbt)
      deposit2.complete?.should == true
    end

    it 'should process a legitimate tx with more than one amount to the same receiving address' do
      address = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          },
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 0.30000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit = address.crypto_deposits.first
      deposit.amount.should == Money.new(200000000, :xbt)
      deposit.complete?.should == true
      CryptoDeposit.count.should == 1
    end

    it 'should complete all deposits belonging to a tx that could be confirmed up to our retry threshhold' do
      address1 = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      address2 = create :bitcoin_address, address: 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4'
      transaction_data = {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 0,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          },
          {
            'category' => 'receive',
            'address' => 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4',
            'amount' => 0.30000000
          }
        ]
      }
      # 1
      CryptoTransactor.stub(transaction: transaction_data)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1 = address1.crypto_deposits.first
      deposit1.pending?.should == true
      deposit1.retries.should == 1
      deposit2 = address2.crypto_deposits.first
      deposit2.pending?.should == true
      deposit2.retries.should == 1
      # 2
      transaction_data['confirmations'] = 2
      CryptoTransactor.stub(transaction: transaction_data)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1.reload
      deposit1.retries.should == 2
      deposit2.reload
      deposit2.retries.should == 2
      # 3
      transaction_data['confirmations'] = 3
      CryptoTransactor.stub(transaction: transaction_data)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1.reload
      deposit1.retries.should == 3
      deposit2.reload
      deposit2.retries.should == 3
      # 4
      transaction_data['confirmations'] = 4
      CryptoTransactor.stub(transaction: transaction_data)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1.reload
      deposit1.retries.should == 4
      deposit2.reload
      deposit2.retries.should == 4
      # 5
      transaction_data['confirmations'] = 6
      CryptoTransactor.stub(transaction: transaction_data)
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      deposit1.reload
      deposit1.amount.should == Money.new(170000000, :xbt)
      deposit1.complete?.should == true
      deposit2.reload
      deposit2.amount.should == Money.new(30000000, :xbt)
      deposit2.complete?.should == true
    end

    it 'should mark all deposits as unconfirmed belonging to a tx that could not be confirmed after our retry threshhold' do
      address1 = create :bitcoin_address, address: 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR'
      address2 = create :bitcoin_address, address: 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4'
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 0,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          },
          {
            'category' => 'receive',
            'address' => 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4',
            'amount' => 0.30000000
          }
        ]
      })
      5.times do
        CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      end
      address1.crypto_deposits.first.unconfirmed?.should == true
      address2.crypto_deposits.first.unconfirmed?.should == true
    end

    it 'should ignore deposits into hot wallet' do
      ENV.stub('xbt_hot' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR')
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 20,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          }
        ]
      })
      CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      CryptoDeposit.count.should == 0
    end

    it 'should gracefully handle rpc client connection failure and reschedule tx' do
      CryptoTransactor.stub(:transaction).and_raise(Errno::ETIMEDOUT)
      lambda{CryptoDepositTransactor.receive :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'}.should raise_error('XBT Server Down')
    end

    it 'should log a tx with no addresses belonging to it' do
      CryptoTransactor.stub(transaction: {
        'txid' => '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d',
        'confirmations' => 0,
        'details' => [
          {
            'category' => 'receive',
            'address' => 'mj954BQYFKc9LyzEPU4GeRoCFQYib1KPmR',
            'amount' => 1.70000000
          },
          {
            'category' => 'receive',
            'address' => 'mimoZNLcP2rrMRgdeX5PSnR7AjCqQveZZ4',
            'amount' => 0.30000000
          }
        ]
      })
      transactor = CryptoDepositTransactor.new :xbt, '1535b345d46e51c7bec210d24e662368cfddbc6f4ec33f7a3e2807c4a35f7f3d'
      transactor.should_receive :log_transaction
      transactor.receive
    end

  end

end

