# frozen_string_literal: true

class Mutations::Users::ResetApiToken < Mutations::BaseMutation
  description "Generate a new API token for the current user. " \
              "**Only available when using a first-party OAuth application.**"

  field :api_token, String, null: true, description: "The newly generated API token."
  field :errors, [String], null: false, description: "Error messages if token reset failed."

  def resolve
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to reset your API token." if user.nil?

    # The plaintext token this returns is a long-lived credential that grants
    # full, scope-less access to the account (see `token_auth` in
    # BaseMutation#ready?), so it must never be handed to a third-party client
    # holding nothing more than the 'write' scope.
    require_permissions!(:first_party)

    token = user.reset_api_token
    if token
      { api_token: token, errors: [] }
    else
      { api_token: nil, errors: user.errors.full_messages }
    end
  end
end
