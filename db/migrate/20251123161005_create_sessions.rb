class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.boolean :active, default: true, null: false
      t.string :remember_token
      t.datetime :remember_created_at

      t.timestamps
    end
    add_index :sessions, :active
    add_index :sessions, :remember_token, unique: true
  end
end
