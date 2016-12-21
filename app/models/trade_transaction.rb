class TradeTransaction < ActiveRecord::Base

  belongs_to :source, class_name: 'Trade'
  belongs_to :target, class_name: 'Trade'
  has_one :finance_transaction, as: :related, class_name: 'Finance::Transaction'
  validates :source, presence: true
  validates :target, presence: true
  validates :rate_currency, presence: true
  validates :quantity_currency, presence: true
  validates :source_fee_currency, presence: true
  validates :target_fee_currency, presence: true
  validates :rate_subunit, presence: true
  validates :quantity_subunit, presence: true
  validates :source_fee_subunit, presence: true
  validates :target_fee_subunit, presence: true
  monetize :rate_subunit, as: 'rate', with_model_currency: :rate_currency
  monetize :price_subunit, as: 'price', with_model_currency: :rate_currency
  monetize :quantity_subunit, as: 'quantity', with_model_currency: :quantity_currency
  monetize :source_fee_subunit, as: 'source_fee', with_model_currency: :source_fee_currency
  monetize :target_fee_subunit, as: 'target_fee', with_model_currency: :target_fee_currency
  after_initialize :setup

  default_scope {order created_at: :desc}

  scope :pair, ->(quantity_currency, rate_currency){where("quantity_currency = ? AND rate_currency = ? OR quantity_currency = ? AND rate_currency = ?", quantity_currency, rate_currency, rate_currency, quantity_currency)}
  scope :within, ->(hours){where "created_at >= ?", Time.now - hours}

  def invert
    TradeTransactionInvert.new self
  end

  def invert_to quantity_currency, rate_currency
    self.quantity_currency == quantity_currency.to_s.upcase ? self : self.invert
  end

private
  
  def setup
    unless price
      Money.add_rate quantity_currency, rate_currency, rate.amount
      self.price = quantity.exchange_to rate_currency
    end
  end

end
