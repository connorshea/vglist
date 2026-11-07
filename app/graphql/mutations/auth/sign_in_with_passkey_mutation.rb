# frozen_string_literal: true

class Mutations::Auth::SignInWithPasskeyMutation < GraphQL::Schema::Mutation
  include Mutations::Auth::SignInPayload

  description "Sign in with a passkey. Takes the browser's response to the options from `passkeyAuthenticationOptions` and returns a JWT token, like `signIn`."

  argument :response, GraphQL::Types::JSON, required: true, description: "AuthenticationResponseJSON from `navigator.credentials.get`."

  def resolve(response:)
    passkey = PasskeyService.verify_authentication(response)
    sign_in(passkey.user)
  rescue PasskeyService::Error => e
    sign_in_failure(e.message)
  end
end
