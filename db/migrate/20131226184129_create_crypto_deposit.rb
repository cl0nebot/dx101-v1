class CreateCryptoDeposit < ActiveRecord::Migration
  def change
    create_table :crypto_deposits do |t|
      t.references :crypto_address, index: true
      t.string :txid, index: true
      t.integer :status, index: true
      t.integer :confirmations
      t.integer :retries
      t.decimal :amount_subunit, precision: 65, scale: 10
      t.timestamp :complete_at
      t.timestamp :canceled_at
      t.timestamps
    end
  end
end
