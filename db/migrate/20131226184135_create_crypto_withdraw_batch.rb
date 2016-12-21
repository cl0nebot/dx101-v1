class CreateCryptoWithdrawBatch < ActiveRecord::Migration
  def change
    create_table :crypto_withdraw_batches do |t|
      t.string :txid, index: true, unique: true
      t.string :currency
      t.decimal :fee_subunit, precision: 65, scale: 10
      t.timestamps
    end
  end
end
