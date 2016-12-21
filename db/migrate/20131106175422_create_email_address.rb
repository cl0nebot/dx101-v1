class CreateEmailAddress < ActiveRecord::Migration
  def change
    create_table :email_addresses do |t|
      t.references :user
      t.string :email, unique: true, index: true
      t.string :verification_code, unique: true
      t.timestamp :verified_at
      t.timestamp :primary_at
      t.timestamps
    end
  end
end
