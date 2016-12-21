class CreateSetting < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.references :user, index: true
      t.integer :setting_type, index: true
      t.text :meta
      t.timestamps
    end
  end
end
