
#
# A wrapper for the different crypto libraries in the case that they do not all work with the bitcoin client gem we are using
#

class CryptoTransactor

  attr_accessor :currency, :client

  def initialize currency
    @currency = currency.downcase.to_sym
    @client = CryptoTransactor.client @currency
  end
  
  def new_address
    @client.new_address
  end

  def validate_address address
    @client.validate_address address
  end

  def transaction id
    @client.transaction id
  end

  def balance
    @client.balance
  end

  def info
    @client.info
  end

  def send_many addresses_amounts, comment = nil
    @client.send_many "", addresses_amounts, 0, comment
  end

  def self.client currency
    raise "Invalid Currency" unless Finance.crypto_currencies.include? currency.to_sym
    cs = currency.to_s
    host = ENV["#{cs}_host"]
    port = ENV["#{cs}_port"]
    ssl = (ENV["#{cs}_ssl"] == 'true')
    user = ENV["#{cs}_user"]
    pass = ENV["#{cs}_pass"]
    Bitcoin::Client.new(user, pass, {host: host, port: port, ssl: ssl})
  end

  def self.new_address currency
    transactor = CryptoTransactor.new currency
    transactor.new_address
  end

  def self.validate_address currency, address
    transactor = CryptoTransactor.new currency
    transactor.validate_address address
  end

  def self.transaction currency, id
    transactor = CryptoTransactor.new currency
    transactor.transaction id
  end

  def self.balance currency
    transactor = CryptoTransactor.new currency
    transactor.balance
  end

  def self.info currency
    transactor = CryptoTransactor.new currency
    transactor.info
  end

  def self.send_many currency, addresses_amounts, comment = nil
    transactor = CryptoTransactor.new currency
    transactor.send_many addresses_amounts, comment
  end

end
