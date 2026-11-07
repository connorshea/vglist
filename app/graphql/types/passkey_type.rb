# frozen_string_literal: true

module Types
  class PasskeyType < Types::BaseObject
    description "A passkey the current user can sign in with. Only visible to its owner."

    field :id, ID, null: false, description: "ID of the passkey."
    field :nickname, String, null: false, description: "The name the user gave the passkey, e.g. \"iPhone\"."
    field :backed_up, Boolean, null: false, description: "Whether the passkey is synced to other devices (e.g. by a password manager), rather than kept on a single device or security key."
    field :last_used_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When the passkey was last used to sign in. `null` if it hasn't been used yet."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the passkey was added."
  end
end
