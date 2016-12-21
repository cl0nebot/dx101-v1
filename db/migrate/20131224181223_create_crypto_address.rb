class CreateCryptoAddress < ActiveRecord::Migration
  def change
    create_table :crypto_addresses do |t|
      t.references :user, index: true
      t.string :address, index: true, unique: true
      t.string :currency, index: true
      t.string :label
      t.timestamp :hide_at
      t.timestamps
    end
  end
end
