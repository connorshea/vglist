class Mutations::Users::ResetApiToken < Mutations::BaseMutation
  description "Generate a new API token for the current user."

  field :api_token, String, null: true, description: "The newly generated API token."
  field :errors, [String], null: false, description: "Error messages if token reset failed."

  def resolve
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to reset your API token." if user.nil?

    token = user.reset_api_token
    if token
      { api_token: token, errors: [] }
    else
      { api_token: nil, errors: user.errors.full_messages }
    end
  end
end
