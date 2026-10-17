class AddDegreeLevelToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :degree_level, :integer
  end
end
