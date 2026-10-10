class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :full_name, :string
    add_column :users, :role, :integer, null: false, default: 0
    add_reference :users, :manager, foreign_key: { to_table: :users }, null: true
    add_index :users, :role
  end
end
