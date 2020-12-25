class AddPrivacyEnumToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :privacy, :integer, default: 0, null: false
  end
end
