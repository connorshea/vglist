# frozen_string_literal: true

class Mutations::Passkeys::RenamePasskey < Mutations::BaseMutation
  description "Rename one of the current user's passkeys."

  argument :id, ID, required: true, description: "The ID of the passkey to rename."
  argument :nickname, String, required: true, description: "The new name for the passkey."

  field :passkey, Types::PasskeyType, null: true, description: "The renamed passkey. `null` if there are errors."
  field :errors, [String], null: false, description: "Error messages if the passkey couldn't be renamed."

  def resolve(id:, nickname:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to rename a passkey." if user.nil?

    # Scoped to the current user, so another user's passkey is "not found".
    passkey = user.webauthn_credentials.find_by(id: id)
    raise GraphQL::ExecutionError, "Passkey not found." if passkey.nil?

    if passkey.update(nickname: nickname)
      { passkey: passkey, errors: [] }
    else
      { passkey: nil, errors: passkey.errors.full_messages }
    end
  end
end
