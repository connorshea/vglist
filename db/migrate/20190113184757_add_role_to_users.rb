class AddRoleToUsers < ActiveRecord::Migration[5.2]
  def change
    # Default to 'member' role for new users.
    add_column :users, :role, :integer, null: false, default: 0
  end
end
