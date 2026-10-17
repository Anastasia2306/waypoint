class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :direction, :string
    add_column :users, :course, :integer
    add_column :users, :group_name, :string
  end
end
