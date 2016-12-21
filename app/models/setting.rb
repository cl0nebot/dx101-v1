class Setting < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  validates :user, presence: true
  validates :setting_type, presence: true
  enum setting_type: {
    balance_currencies: 0,
    market_currencies: 1
  }
  after_initialize :meta_from_json
  before_save :meta_to_json
  after_save :meta_from_json

private

  def meta_to_json
    self.meta = meta.to_json if meta and ['Array', 'Hash'].include? meta.class.name
  end

  def meta_from_json
    self.meta = JSON.parse meta if meta and meta.class.name == 'String'
  end

end
