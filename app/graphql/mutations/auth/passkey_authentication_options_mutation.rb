# frozen_string_literal: true

class Mutations::Auth::PasskeyAuthenticationOptionsMutation < GraphQL::Schema::Mutation
  description "Start signing in with a passkey. Returns the options to pass to `navigator.credentials.get` (PublicKeyCredentialRequestOptionsJSON). The challenge in them is single-use and expires after a few minutes."

  field :options, GraphQL::Types::JSON, null: false, description: "PublicKeyCredentialRequestOptionsJSON for the browser's WebAuthn API."

  def resolve
    # No allow list: the browser offers any discoverable passkey it has for
    # this site, and the response tells us which account it belongs to.
    options = WebAuthn::Credential.options_for_get(user_verification: 'required')
    WebauthnChallenge.issue!(challenge: options.challenge, purpose: :authentication)

    { options: options.as_json }
  end
end
