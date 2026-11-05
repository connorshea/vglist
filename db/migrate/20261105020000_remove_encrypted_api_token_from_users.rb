# frozen_string_literal: true

# API tokens (X-User-Email/X-User-Token auth) were removed along with the
# public third-party API.
class RemoveEncryptedApiTokenFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :encrypted_api_token, :string
  end
end
