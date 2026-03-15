class AddJwtVersionToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :jwt_version, :integer, null: false, default: 0
  end
end
