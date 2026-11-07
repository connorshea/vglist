# frozen_string_literal: true

# The WebAuthn user handle: a random, opaque ID that authenticators store with
# a passkey. It's generated the first time a user registers a passkey, and is
# never the numeric user ID, so passkeys don't leak it.
class AddWebauthnIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :webauthn_id, :string
    add_index :users, :webauthn_id, unique: true
  end
end
