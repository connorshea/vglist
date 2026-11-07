# frozen_string_literal: true

class Mutations::Passkeys::DeletePasskey < Mutations::BaseMutation
  description "Remove one of the current user's passkeys, so it can no longer be used to sign in. Their password and other passkeys keep working."

  argument :id, ID, required: true, description: "The ID of the passkey to remove."

  field :deleted, Boolean, null: false, description: "Whether the passkey was removed."

  def resolve(id:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to remove a passkey." if user.nil?

    # Scoped to the current user, so another user's passkey is "not found".
    passkey = user.webauthn_credentials.find_by(id: id)
    raise GraphQL::ExecutionError, "Passkey not found." if passkey.nil?

    { deleted: passkey.destroy.destroyed? }
  end
end
