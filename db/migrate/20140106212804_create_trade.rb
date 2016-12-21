class CreateTrade < ActiveRecord::Migration
  def change
    create_table :trades do |t|
      t.references :user, index: true
      t.integer :transfer_type, index: true
      t.integer :trade_type, index: true
      t.integer :status, index: true
      t.string :rate_currency, index: true
      t.string :quantity_currency, index: true
      t.decimal :rate_subunit, precision: 65, scale: 10, index: true
      t.decimal :stop_subunit, precision: 65, scale: 10, index: true
      t.decimal :quantity_subunit, precision: 65, scale: 10, index: true
      t.decimal :quantity_filled_subunit, precision: 65, scale: 10, index: true
      t.decimal :fee, precision: 65, scale: 10, index: true
      t.boolean :basic, index: true # if simple ui and should not "show" in trading section
      t.boolean :fok, index: true # fill all or kill (cancel)
      t.boolean :ioc, index: true # immediate or cancel (fill all or partial and then cancel)
      t.timestamp :processed_at, index: true
      t.timestamp :completed_at, index: true
      t.timestamp :canceled_at, index: true
      t.timestamps index: true
    end
  end
end
