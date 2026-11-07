# frozen_string_literal: true

class Mutations::Passkeys::RegisterPasskey < Mutations::BaseMutation
  description "Finish adding a passkey to the current user's account. Takes the browser's response to the options from `passkeyRegistrationOptions`."

  argument :response, GraphQL::Types::JSON, required: true, description: "RegistrationResponseJSON from `navigator.credentials.create`."
  argument :nickname, String, required: false, description: "A name for the passkey, e.g. \"iPhone\". Defaults to \"Unnamed passkey\"."

  field :passkey, Types::PasskeyType, null: true, description: "The new passkey. `null` if there are errors."
  field :errors, [String], null: false, description: "Error messages if the passkey couldn't be added."

  def resolve(response:, nickname: nil)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to add a passkey." if user.nil?

    return failure("Confirm your email address before adding a passkey.") unless user.confirmed?

    credential = PasskeyService.verify_registration(response, user: user)
    return failure("This passkey is already registered.") if WebauthnCredential.exists?(external_id: credential.id)

    passkey = user.webauthn_credentials.build(
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: credential.sign_count,
      backed_up: credential.backed_up? || false,
      nickname: nickname
    )

    if passkey.save
      PasskeyMailer.with(passkey: passkey).passkey_added.deliver_later
      { passkey: passkey, errors: [] }
    else
      failure(*passkey.errors.full_messages)
    end
  rescue PasskeyService::Error => e
    failure(e.message)
  rescue ActiveRecord::RecordNotUnique
    failure("This passkey is already registered.")
  end

  private

  def failure(*messages)
    { passkey: nil, errors: messages }
  end
end
