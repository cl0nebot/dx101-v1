class CreateRole < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :user, index: true
      t.integer :role_type, index: true
      t.timestamps
    end
  end
end
