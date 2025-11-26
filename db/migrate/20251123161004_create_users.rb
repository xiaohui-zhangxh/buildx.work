class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name
      t.integer :failed_login_attempts, default: 0
      t.datetime :locked_at
      t.datetime :password_changed_at
      t.datetime :confirmed_at
      t.string :confirmation_token
      t.datetime :confirmation_sent_at
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :confirmation_token, unique: true
  end
end
