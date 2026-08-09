# frozen_string_literal: true

class Mutations::Users::UpdateEmail < Mutations::BaseMutation
  description "Update the current user's email address. Requires current password for verification. " \
              "The new email must be confirmed before it takes effect. " \
              "**Only available when using a first-party OAuth application.**"

  argument :new_email, String, required: true, description: "The new email address."
  argument :current_password, String, required: true, description: "The user's current password for verification."

  field :user, Types::UserType, null: true, description: "The updated user."
  field :errors, [String], null: false, description: "Error messages if update failed."

  def resolve(new_email:, current_password:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to update your email." if user.nil?

    # The email address is the account's recovery channel, so changing it is an
    # auth-factor change. The password check below is the primary control; this
    # keeps a third-party client that has obtained the password some other way
    # from using a 'write' token to complete an account takeover.
    require_permissions!(:first_party)

    return { user: nil, errors: ["Current password is incorrect."] } unless user.valid_password?(current_password)

    if user.update(email: new_email)
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
