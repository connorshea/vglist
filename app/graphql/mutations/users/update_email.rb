class Mutations::Users::UpdateEmail < Mutations::BaseMutation
  description "Update the current user's email address. Requires current password for verification. " \
              "The new email must be confirmed before it takes effect."

  argument :new_email, String, required: true, description: "The new email address."
  argument :current_password, String, required: true, description: "The user's current password for verification."

  field :user, Types::UserType, null: true, description: "The updated user."
  field :errors, [String], null: false, description: "Error messages if update failed."

  def resolve(new_email:, current_password:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to update your email." if user.nil?

    unless user.valid_password?(current_password)
      return { user: nil, errors: ["Current password is incorrect."] }
    end

    if user.update(email: new_email)
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
