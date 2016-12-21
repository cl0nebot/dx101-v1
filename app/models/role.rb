class Role < ActiveRecord::Base

  has_paper_trail meta: {user_id: :user_id}
  belongs_to :user
  validates :user, presence: true
  validates :role_type, presence: true
  enum role_type: {
    admin: 0,
    agent: 1,
    manager: 2,
    vendor: 3
  }

end
