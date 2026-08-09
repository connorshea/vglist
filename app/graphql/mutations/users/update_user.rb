# frozen_string_literal: true

class Mutations::Users::UpdateUser < Mutations::BaseMutation
  description "Update the current user's profile. Changing `privacy` is " \
              "**only available when using a first-party OAuth application.**"

  argument :bio, String, required: false, description: "User profile description."
  argument :privacy, Types::Enums::UserPrivacyType, required: false, description: "Account privacy setting. **Only available when using a first-party OAuth application.**"
  argument :hide_days_played, Boolean, required: false, description: "Whether to hide days played on profile."

  field :user, Types::UserType, null: true, description: "The updated user."
  field :errors, [String], null: false, description: "Error messages if update failed."

  def resolve(**args)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to update your profile." if user.nil?

    # Only update attributes that were provided
    update_params = args.compact

    # `privacy` decides whether the account's library and activity are visible
    # to the world, so it's a security setting rather than a profile field.
    # `bio` and `hideDaysPlayed` are ordinary profile writes that third-party
    # clients can legitimately make, so only gate the mutation when privacy is
    # actually being changed.
    require_permissions!(:first_party) if update_params.key?(:privacy)

    if user.update(update_params)
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
