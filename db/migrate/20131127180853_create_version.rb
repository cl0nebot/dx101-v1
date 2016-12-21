class CreateVersion < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.references :user, index: true
      t.references :item, polymorphic: true, index: true, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.text :object
      t.string :ip_address
      t.string :user_agent
      t.timestamp :created_at
    end
  end
end
