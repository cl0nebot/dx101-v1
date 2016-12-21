class MarketData

  def self.last_transaction quantity_currency, rate_currency
    transaction = TradeTransaction.pair(quantity_currency, rate_currency).first
    transaction.invert_to quantity_currency, rate_currency if transaction
  end

  def self.last_rate quantity_currency, rate_currency
    transaction = last_transaction quantity_currency, rate_currency
    transaction.rate if transaction
  end

  def self.parse_pair_stats hours, quantity_currency, rate_currency, transactions, transactions_for_change
    last = transactions.first ? transactions.first.rate : self.last_rate(quantity_currency, rate_currency)
    high = get_high transactions
    low = get_low transactions
    volume = get_volume transactions
    change = get_change transactions, transactions_for_change
    chart = get_chart hours, 10.minutes, quantity_currency, rate_currency, transactions
    {last: last, high: high, low: low, volume: volume, change: change, chart: chart}
  end

  def self.parse_pair_stats_from_all_transactions hours, quantity_currency, rate_currency, transactions
    time = Time.now
    transactions = transactions.select{|t| (t.quantity_currency == quantity_currency.to_s.upcase and t.rate_currency == rate_currency.to_s.upcase) or 
                                           (t.quantity_currency == rate_currency.to_s.upcase and t.rate_currency == quantity_currency.to_s.upcase)}
    transactions = invert_array_of_transactions_to quantity_currency, rate_currency, transactions
    transactions, transactions_for_change = transactions.partition{|t| t.created_at >= time - hours}
    parse_pair_stats hours, quantity_currency, rate_currency, transactions, transactions_for_change
  end

  def self.stats hours
    transactions = TradeTransaction.within(hours * 2)
    stats = {}
    ([:pmu] + Finance.crypto_currencies).each do |c|
      stats[c] = {}
      ([:pmu] + Finance.crypto_currencies).each do |cc|
        stats[c][cc] = parse_pair_stats_from_all_transactions hours, cc, c, transactions unless c == cc
      end
    end
    stats
  end

  def self.get_high transactions
    max = transactions.max_by{|t| t.rate}
    max.rate if max
  end

  def self.get_low transactions
    min = transactions.min_by{|t| t.rate}
    min.rate if min
  end

  def self.get_volume transactions
    transactions.sum{|t| t.quantity}
  end

  def self.get_change transactions, transactions_for_change
    old_volume = get_volume(transactions_for_change) || Money.new(0, currency)
    current_volume = get_volume(transactions) || Money.new(0, currency)
    if current_volume <= 0 and old_volume <= 0
      return 0.00
    elsif current_volume <= 0
      return -100
    elsif old_volume <= 0
      return nil
    else
      return (current_volume - old_volume) / old_volume * 100
    end
  end

  def self.get_open transactions
    open = transactions.min_by{|t| t.created_at}
    open.rate if open
  end

  def self.get_close transactions
    close = transactions.max_by{|t| t.created_at}
    close.rate if close
  end

  def self.get_chart hours, increment, quantity_currency, rate_currency, transactions
    end_on = Time.now
    start_on = end_on - hours
    chart_data = []
    lr = last_rate quantity_currency, rate_currency
    while end_on >= start_on
      trans = transactions.select{|t| t.created_at <= end_on and t.created_at > end_on - increment}
      # date, open, high, low, close, volume
      last = chart_data.first || [nil,nil,nil,nil,nil,nil]
      open = get_open(trans) || last[4] || lr
      high = get_high(trans)
      low = get_low(trans)
      close = get_close(trans) || open
      volume = get_volume trans
      chart_data.unshift({date: end_on, open: open, high: high, low: low, close: close, volume: volume})
      end_on -= increment
    end
    chart_data
  end

  def self.invert_array_of_transactions_to quantity_currency, rate_currency, transactions
    transactions.map{|t| t.invert_to quantity_currency, rate_currency}
  end
  
end
