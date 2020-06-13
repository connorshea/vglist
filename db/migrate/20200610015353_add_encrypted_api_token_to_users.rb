# typed: true

class AddEncryptedApiTokenToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :encrypted_api_token, :varchar, null: true
    remove_column :users, :authentication_token, :varchar, limit: 30
  end
end
