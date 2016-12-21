class Trade < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  has_many :source_transactions, class_name: 'TradeTransaction', foreign_key: :source_id, dependent: :destroy
  has_many :target_transactions, class_name: 'TradeTransaction', foreign_key: :target_id, dependent: :destroy
  has_one :trade_holding, as: :related, class_name: 'Finance::Transaction'
  validates :user, presence: true
  validates :transfer_type, presence: true
  validates :trade_type, presence: true
  validates :rate_currency, presence: true
  validates :rate_subunit, presence: true, numericality: {greater_than: 0}, if: :lmt_like?
  validates :stop_subunit, presence: true, numericality: {greater_than: 0}, if: :stop_like?
  validates :quantity_currency, presence: true
  validates :quantity_subunit, presence: true, numericality: {greater_than: 0}
  validates :fee, presence: true
  validate :fok_or_ioc
  validate :quantity_amount_for_currency
  monetize :rate_subunit, as: 'rate', with_model_currency: :rate_currency
  monetize :stop_subunit, as: 'stop_rate', with_model_currency: :rate_currency
  monetize :quantity_subunit, as: 'quantity', with_model_currency: :quantity_currency
  monetize :quantity_filled_subunit, as: 'quantity_filled', with_model_currency: :quantity_currency
  enum transfer_type: {
    buy: 0,
    sell: 1
  }
  enum trade_type: {
    market: 0,
    lmt: 1,
    stop: 2,
    stop_lmt: 3
  }
  enum status: {
    pending: 0,
    pending_funds: 1,
    processing: 2,
    complete: 3,
    canceled: 4
  }
  after_initialize :setup
  after_create :execute

  default_scope {order created_at: :desc}

  scope :basic, -> {where basic: 1}
  scope :advanced, -> {where basic: 0}
  scope :open, -> {where 'status in (?,?,?)', Trade.statuses[:pending], Trade.statuses[:pending_funds], Trade.statuses[:processing]}

  def invert
    TradeInvert.new self
  end

  def invert_to quantity_currency, rate_currency
    self.quantity_currency == quantity_currency.to_s.upcase ? self : self.invert
  end

  def self.invert_all_to quantity_currency, rate_currency, trades
    trades.map{|t| t.invert_to quantity_currency, rate_currency}
  end

  def transactions
    source_transactions + target_transactions
  end

  def market_like_matches
    Trade.processing
         .where('processed_at <= ?', processed_at)
         .where('trade_type = ? OR trade_type = ?', Trade.trade_types[:market], Trade.trade_types[:stop])
         .where('(transfer_type = ? AND quantity_currency = ? AND rate_currency = ?) OR (transfer_type = ? AND quantity_currency = ? AND rate_currency = ?)', Trade.transfer_types[transfer_type], rate_currency, quantity_currency, Trade.transfer_types[invert_transfer_type], quantity_currency, rate_currency)
         .reorder(processed_at: :asc)
  end

  def lmt_like_matches
    trades = Trade.select("*, IF(quantity_currency = '#{rate_currency}', 1/rate_subunit, rate_subunit) AS inverted_rate_subunit")
                  .processing
                  .where('processed_at <= ?', processed_at)
                  .where('trade_type = ? OR trade_type = ?', Trade.trade_types[:lmt], Trade.trade_types[:stop_lmt])
                  .where('(transfer_type = ? AND quantity_currency = ? AND rate_currency = ?) OR (transfer_type = ? AND quantity_currency = ? AND rate_currency = ?)', Trade.transfer_types[transfer_type], rate_currency, quantity_currency, Trade.transfer_types[invert_transfer_type], quantity_currency, rate_currency)
                  .reorder("inverted_rate_subunit #{buy? ? 'ASC' : 'DESC'}")
    trades = trades.having((buy? ? 'inverted_rate_subunit <= ?' : 'inverted_rate_subunit >= ?'), rate_subunit) if lmt_like?
    trades
  end

  def all_matches
    market_like_matches + lmt_like_matches
  end

  def can_fill?
    trades = Trade.invert_all_to quantity_currency, rate_currency, all_matches
    quantity <= trades.sum(&:quantity_required)
  end

  def invert_transfer_type
    self.buy? ? :sell : :buy
  end

  def quantity_required
    self.quantity - self.quantity_filled
  end

  def market_like?
    self.market? or self.stop?
  end

  def lmt_like?
    self.lmt? or self.stop_lmt?
  end

  def stop_like?
    self.stop? or self.stop_lmt?
  end

  def cancel
    ActiveRecord::Base.transaction do
      self.update_attributes! status: :canceled, canceled_at: Time.now, processed_at: nil
      if lmt_like?
        refund = buy? ? rate * quantity_required.amount : quantity_required
        total_fee = refund * fee
        # TODO: Remove this hack to set the trade fees to zero
        total_fee = total_fee - total_fee
        user.move_funds_for_trade_cancellation((refund + total_fee), self) 
      end
    end
  end

  def reprocess
    if self.stop_like?
      self.update_attributes! status: :pending, processed_at: nil, canceled_at: nil
    else
      self.update_attributes! status: :processing, processed_at: Time.now, canceled_at: nil
    end
  end

  def can_cover? amount
    self.user.can_cover? amount
  end

  def filled?
    self.quantity_filled == self.quantity
  end

  def trade_type_for_display
    if self.lmt?
      display = 'Limit'
    elsif self.stop_lmt?
      display = 'Stop Limit'
    else
      display = self.trade_type.to_s.capitalize
    end
    display
  end

  def status_for_display
    processing? ? 'Open' : (pending_funds? ? 'Pending Funds' : status.to_s.capitalize)
  end

  def execute
    if lmt_like? and !trade_holding
      amount = buy? ? rate * quantity.amount : quantity
      total_fee = amount * fee
      # TODO: Remove this hack to set the trade fees to zero
      total_fee = total_fee - total_fee
      user.move_funds_for_trade((amount + total_fee), self) if can_cover? amount + total_fee
      reload
    end
    unless lmt_like? and !trade_holding
      unless stop_like?
        if Rails.env == 'production'
          TradingWorker.perform_async self.id
        else
          TradeTransactor.execute self
        end
      end
    else
      set_pending_funds
    end
  end

  def set_pending_funds
    update_attributes! status: :pending_funds, processed_at: nil
    # TODO: send notification that funds are needed to process this trade
  end

  def self.bids_asks_for quantity_currency, rate_currency
    trades = Trade.processing.where('(trade_type = ? OR trade_type = ?) AND ((quantity_currency = ? and rate_currency = ?) OR (quantity_currency = ? and rate_currency = ?))', Trade.trade_types[:lmt], Trade.trade_types[:stop_lmt], quantity_currency.to_s.upcase, rate_currency.to_s.upcase, rate_currency.to_s.upcase, quantity_currency.to_s.upcase)
    trades = invert_all_to quantity_currency, rate_currency, trades
    bids, asks = trades.partition{|t| t.buy?}
    return bids.sort_by{|b| b.rate}.reverse,
           asks.sort_by{|a| a.rate}
  end

private

  def setup
    if self.stop_like?
      self.status = :pending unless self.status
    else
      self.status = :processing unless self.status
      self.processed_at = Time.now
    end
    self.basic = 0 if self.basic.nil?
    self.fok = 0 if self.fok.nil?
    self.ioc = 0 if self.ioc.nil?
    self.quantity_filled_subunit = 0 if self.quantity_filled_subunit.nil?
    self.fee = self.user.trading_fee if self.fee.nil?
  end

  def fok_or_ioc
    errors[:base] << 'Can not FOK and IOC' if fok == true and ioc == true
  end

  def quantity_amount_for_currency
    if quantity_currency == 'PMU' and quantity < Money.new(10, :pmu)
      errors[:base] << "Your quantity must be at least PMU .10"
    elsif Finance.crypto_currencies.include? quantity_currency.downcase.to_sym and quantity < Money.new(10, quantity_currency)
      errors[:base] << "Your quantity must be at least #{quantity_currency} .0000001"
    end
  end

end
