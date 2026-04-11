class Mutations::Users::UpdateUser < Mutations::BaseMutation
  description "Update the current user's profile."

  argument :bio, String, required: false, description: "User profile description."
  argument :privacy, Types::Enums::UserPrivacyType, required: false, description: "Account privacy setting."
  argument :hide_days_played, Boolean, required: false, description: "Whether to hide days played on profile."

  field :user, Types::UserType, null: true, description: "The updated user."
  field :errors, [String], null: false, description: "Error messages if update failed."

  def resolve(**args)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to update your profile." if user.nil?

    # Only update attributes that were provided
    update_params = args.compact

    if user.update(update_params)
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
