class CreateCryptoWithdraw < ActiveRecord::Migration
  def change
    create_table :crypto_withdraws do |t|
      t.references :user, index: true
      t.references :crypto_withdraw_batch, index: true
      t.string :address
      t.integer :status, index: true
      t.string :currency
      t.decimal :amount_subunit, precision: 65, scale: 10
      t.decimal :fee_subunit, precision: 65, scale: 10 # fee we charge to withdraw
      t.timestamp :complete_at
      t.timestamp :canceled_at
      t.timestamps
    end
  end
end
