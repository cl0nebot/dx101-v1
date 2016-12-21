class User < ActiveRecord::Base

  has_paper_trail meta: {user_id: :id}, on: [:update, :destroy]
  has_many :roles, dependent: :destroy, autosave: true
  has_many :settings, dependent: :destroy, autosave: true
  has_many :accounts, class_name: 'Finance::Account'
  has_many :email_addresses, dependent: :destroy, autosave: true
  has_many :crypto_addresses
  has_many :crypto_deposits, through: :crypto_addresses
  has_many :crypto_withdraws
  has_many :trades
  has_many :trade_transactions, through: :trades
  has_many :session_histories
  has_many :activity, -> {order 'created_at DESC'}, class_name: 'PaperTrail::Version'
  before_save :encrypt_password, if: :password_changed?, unless: 'password.blank?'
  before_create :set_first_email_as_primary, unless: 'email_addresses.blank?'
  validates :password, confirmation: true, length: {minimum: 8}, format: {with: /(?=.*[a-z])(?=.*[a-z])(?=.*[!@#$%^&*-:])/, message: 'must be at least 8 characters and include at least 1 each of UPPERCASE, lowercase, and special (!@#$%^&*-:)'}, unless: 'password.blank?'
  validates :password_confirmation, presence: true, unless: 'password.blank?', if: :password_changed?
  accepts_nested_attributes_for :roles, :settings, :email_addresses, :crypto_addresses

  def email
    self.email_addresses.primary.first unless self.email_addresses.primary.blank?
  end

  def name
    self.first_name
  end

  def full_name
    self.first_name + ' ' + self.last_name
  end

  def set_first_email_as_primary
    self.email_addresses.first.primary_at = Time.now
  end

  def passwd?(p)
    self.descrypt_password == p
  end

  def mfa?(code)
    ROTP::TOTP.new(self.mfa_secret).verify_with_drift(code, 6)
  end

  def google_mfa_qr_uri
    GoogleQR.new(:data => ROTP::TOTP.new(self.mfa_secret, :issuer => "101.net#{' [dev]' if Rails.env.development?}").provisioning_uri(self.email.email), :size => "200x200").to_s
  end

  def encrypt_password
    self.password = self.scrypt_password
  end

  def scrypt_password
    SCrypt::Password.create self.password
  end

  def descrypt_password
    SCrypt::Password.new self.password
  end

  def verified?
    self.email ? self.email.verified? : false
  end

  def generate_password_reset_code
    code = SecureRandom.hex(8)
    self.update_attribute :password_reset_code, SCrypt::Password.create(code)
    code
  end

  def generate_mfa_secret
     self.update_attribute :mfa_secret, ROTP::Base32.random_base32
  end

  def role(role)
    self.roles.find_by role_type: Role.role_types[role.to_sym]
  end

  def role?(role)
    !!self.role(role)
  end

  def grant(role)
    self.roles.create(role_type: role.to_sym) unless self.role? role
  end

  def admin?
    self.role? :admin
  end

  def balance_currencies
    s = setting :balance_currencies
    s ? s.meta.map{|c| c.downcase.to_sym} : [:xbt, :ltc, :xdg]
  end

  def market_currencies
    s = setting :market_currencies
    s ? s.meta.map{|c| c.downcase.to_sym} : [:xbt, :ltc, :xdg]
  end

  def setting(setting)
    self.settings.find_by setting_type: Setting.setting_types[setting.to_sym]
  end

  def setting?(setting)
    !!self.setting(setting)
  end

  def save_setting(setting, meta = {})
    s = self.setting(setting)
    if s
      s.update_attribute :meta, meta
    else
      self.settings.create(setting_type: setting.to_sym, meta: meta)
    end
  end
  
  def balance
    user_liability = self.find_account :liability, :user_liability
    user_liability.balance
  end

  def can_cover? amount
    self.balance[amount.currency.to_s.downcase.to_sym] >= amount
  end

  def find_account(type, category)
    user = self
   "Finance::#{type.to_s.capitalize}".constantize.find_or_create_by!(user: user, category: Finance::Account.categories[category.to_sym])
  end

  # used for deposits
  def add_funding amount, related = nil
    hot = Finance::Asset.find_by name: 'Hot'
    user_liability = self.find_account :liability, :user_liability
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :deposit,
      debits: [
        {account: hot, amount: amount}
      ],
      credits: [
        {account: user_liability, amount: amount}
      ]
    )
    transaction.save!
  end

  # used when funds are revoked
  def remove_funding amount, related = nil
    hot = Finance::Asset.find_by name: 'Hot'
    user_liability = self.find_account :liability, :user_liability
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :deposit_cancellation,
      debits: [
        {account: user_liability, amount: amount}
      ],
      credits: [
        {account: hot, amount: amount}
      ]
    )
    transaction.save!
  end

  def move_funds_for_withdraw amount, related = nil
    user_liability = self.find_account :liability, :user_liability
    user_withdraw_holdings = self.find_account :liability, :user_withdraw_holdings
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :withdraw_holding,
      debits: [
        {account: user_liability, amount: amount}
      ],
      credits: [
        {account: user_withdraw_holdings, amount: amount}
      ]
    )
    transaction.save!
  end

  def move_funds_for_withdraw_cancellation amount, related = nil
    user_liability = self.find_account :liability, :user_liability
    user_withdraw_holdings = self.find_account :liability, :user_withdraw_holdings
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :withdraw_holding,
      debits: [
        {account: user_withdraw_holdings, amount: amount}
      ],
      credits: [
        {account: user_liability, amount: amount}
      ]
    )
    transaction.save!
  end

  def move_funds_for_trade amount, related = nil
    user_liability = self.find_account :liability, :user_liability
    user_trade_holdings = self.find_account :liability, :user_trade_holdings
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :trade_holding,
      debits: [
        {account: user_liability, amount: amount}
      ],
      credits: [
        {account: user_trade_holdings, amount: amount}
      ]
    )
    transaction.save!
  end
  
  def move_funds_for_trade_cancellation amount, related = nil
    user_liability = self.find_account :liability, :user_liability
    user_trade_holdings = self.find_account :liability, :user_trade_holdings
    transaction = Finance::Transaction.build(
      related: related,
      transaction_type: :trade_cancellation,
      debits: [
        {account: user_trade_holdings, amount: amount}
      ],
      credits: [
        {account: user_liability, amount: amount}
      ]
    )
    transaction.save!
  end

  def trading_fee
    mus = balance[:smu].amount + balance[:pmu].amount
    if mus >= BigDecimal.new(250)
      fee = '.002'
    elsif mus >= BigDecimal.new(100)
      fee = '.0025'
    elsif mus >= BigDecimal.new(50)
      fee = '.003'
    elsif mus >= BigDecimal.new(5)
      fee = '.004'
    else
      fee = '.005'
    end
    BigDecimal.new fee
  end

  def trading_discount
    case trading_fee
    when BigDecimal.new('.002')
      60
    when BigDecimal.new('.0025')
      50
    when BigDecimal.new('.003')
      40
    when BigDecimal.new('.004')
      20
    when BigDecimal.new('.005')
      0
    end
  end

  def buy_pmus amount
    raise 'Must be PMU amount' unless amount.currency.iso_code == 'PMU'
    mu_account = Finance::Asset.find_by name: 'MUs'
    pmus_sold = mu_account.balance[:pmu]
    pmus_available = Money.new(15000000, :pmu) - pmus_sold
    price = Money.new 1000000, :xbt
    total = price * amount.amount
    if can_cover? total
      if pmus_available > 0
        if pmus_available >= amount
          cold = Finance::Asset.find_by name: 'Cold'
          user_liability = find_account :liability, :user_liability
          user_mu_sales = find_account :revenue, :user_mu_sales
          transaction = Finance::Transaction.build(
            transaction_type: :pmu_purchase,
            debits: [
              {account: user_liability, amount: total},
              {account: mu_account, amount: amount}
            ],
            credits: [
              {account: user_mu_sales, amount: total},
              {account: user_liability, amount: amount}
            ]
          )
          transaction.save!
        else
          raise 'Insufficient pMUs Available'
        end
      else
        raise 'Sold Out'
      end
    else
      raise 'Insufficient Funds'
    end
  end

  def buy_smus amount
    raise 'Must be SMU amount' unless amount.currency.iso_code == 'SMU'
    mu_account = Finance::Asset.find_by name: 'MUs'
    raise 'PMUs are not sold out' unless mu_account.balance[:pmu] >= Money.new(15000000, :pmu)
    smu_balance = balance[:smu]
    max_smu = Money.new 25000, :smu
    if smu_balance >= max_smu
      raise 'You can not purchase any more sMUs'
    elsif smu_balance + amount > max_smu
      raise "You can only purchase an additional #{max_smu - smu_balance} sMUs"
    end
    price = Money.new 1000000, :xbt
    total = price * amount.amount
    if can_cover? total
      cold = Finance::Asset.find_by name: 'Cold'
      user_liability = find_account :liability, :user_liability
      user_mu_sales = find_account :revenue, :user_mu_sales
      transaction = Finance::Transaction.build(
        transaction_type: :smu_purchase,
        debits: [
          {account: user_liability, amount: total},
          {account: mu_account, amount: amount}
        ],
        credits: [
          {account: user_mu_sales, amount: total},
          {account: user_liability, amount: amount}
        ]
      )
      transaction.save!
    else
      raise 'Insufficient Funds'
    end
  end


end
