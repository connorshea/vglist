class Mutations::Users::UpdatePassword < Mutations::BaseMutation
  description "Update the current user's password. Requires current password for verification."

  argument :current_password, String, required: true, description: "The user's current password for verification."
  argument :new_password, String, required: true, description: "The new password (minimum 8 characters)."
  argument :new_password_confirmation, String, required: true, description: "Confirmation of the new password."

  field :user, Types::UserType, null: true, description: "The updated user."
  field :errors, [String], null: false, description: "Error messages if update failed."

  def resolve(current_password:, new_password:, new_password_confirmation:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to update your password." if user.nil?

    return { user: nil, errors: ["Current password is incorrect."] } unless user.valid_password?(current_password)

    return { user: nil, errors: ["New password and confirmation do not match."] } if new_password != new_password_confirmation

    if user.update(password: new_password, password_confirmation: new_password_confirmation)
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
