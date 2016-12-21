class CreateSessionHistory < ActiveRecord::Migration
  def change
    create_table :session_histories do |t|
      t.references :user, index: true
      t.references :related, index: true, polymorphic: true # email, phone, api key?
      t.integer :status
      t.string :ip_address
      t.timestamp :created_at
    end
  end
end
