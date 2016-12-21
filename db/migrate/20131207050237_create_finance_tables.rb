class CreateFinanceTables < ActiveRecord::Migration
  def self.up
    create_table :finance_accounts do |t|
      t.references :user, index: true
      t.references :agent, index: true
      t.integer :vendor, index: true
      t.integer :category, index: true
      t.string :name, index: true
      t.string :type, index: true
      t.boolean :contra
      t.timestamps
    end
    create_table :finance_transactions do |t|
      t.integer :transaction_type, index: true
      t.references :related, polymorphic: true, index: true
      t.timestamp :created_at, default: Time.now, null: false
    end
    create_table :finance_amounts do |t|
      t.string :type, index: true
      t.references :account, index: true
      t.references :transaction, index: true
      t.string :currency, index: true
      t.decimal :amount_subunit, precision: 65, scale: 10
    end 
  end
  def self.down
    drop_table :finance_accounts
    drop_table :finance_transactions
    drop_table :finance_amounts
  end
end
