class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :password
      t.string :password_reset_code, unique: true
      t.string :mfa_secret
      t.string :country_residence
      t.string :country_citizenship
      t.timestamp :birth_date
      t.timestamp :tos_agreed_at
      t.timestamps
    end
  end
end
