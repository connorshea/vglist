# frozen_string_literal: true

# Passkeys (WebAuthn credentials) registered by users.
class CreateWebauthnCredentials < ActiveRecord::Migration[7.2]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      # The credential ID, base64url-encoded.
      t.string :external_id, null: false, index: { unique: true }
      # The COSE public key, base64url-encoded.
      t.text :public_key, null: false
      t.bigint :sign_count, null: false, default: 0
      t.string :nickname, null: false
      # Whether the authenticator said the passkey is synced (backed up) to
      # other devices, e.g. through iCloud Keychain or Google Password Manager.
      t.boolean :backed_up, null: false, default: false
      t.datetime :last_used_at
      t.timestamps
    end
  end
end
