# typed: true
class AddUserForeignKeyToExternalAccounts < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :external_accounts, :users, column: :user_id, on_delete: :cascade
  end
end
