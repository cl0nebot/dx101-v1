class Admin::DashboardController < AdminController

  def show
    set_coin_server_info
    set_transactions_with_no_addresses
    set_malleable_or_unconfirmed_deposits
  end

private

  def set_coin_server_info
    @coin_servers = {}
    Finance.crypto_currencies.sort.each do |c|
      puts "Trying: #{c.to_s.upcase}"
      @coin_servers[c] = {'currency' => c.to_s.upcase}
      begin
        Timeout::timeout 5 do
          @coin_servers[c] = @coin_servers[c].merge(CryptoTransactor.info(c))
          @coin_servers[c]['status'] = 'UP'
        end
      rescue => e
        @coin_servers[c]['status'] = 'DOWN'
      end
    end
  end

  def set_transactions_with_no_addresses
    @badtx = []
    begin
      File.open("log/no_address_for_tx.log", "r") do |f|
        i = 0
        f.each_line do |l|
          unless i <= 0
            @badtx << JSON.parse(l.split(' -- : ')[1])
          end
          i += 1
        end
      end
    rescue => e
    end
    @badtx = @badtx.uniq
  end

  def set_malleable_or_unconfirmed_deposits
    @baddeposits = CryptoDeposit.for_admin.includes crypto_address: {user: [:email_addresses]}
  end

end
