class CreateTradeTransaction < ActiveRecord::Migration
  def change
    create_table :trade_transactions do |t|
      t.references :source, index: true
      t.references :target, index: true
      t.string :rate_currency, index: true
      t.string :quantity_currency, index: true
      t.string :source_fee_currency
      t.string :target_fee_currency
      t.decimal :rate_subunit, precision: 65, scale: 10
      t.decimal :price_subunit, precision: 65, scale: 10
      t.decimal :quantity_subunit, precision: 65, scale: 10
      t.decimal :source_fee_subunit, precision: 65, scale: 10
      t.decimal :target_fee_subunit, precision: 65, scale: 10
      t.timestamps index: true
    end
  end
end
