class CreateSystemConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_configs do |t|
      t.string :key
      t.text :value
      t.text :description
      t.string :category

      t.timestamps
    end
    add_index :system_configs, :key, unique: true
  end
end
