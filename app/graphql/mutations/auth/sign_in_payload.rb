# frozen_string_literal: true

# The fields and checks shared by the mutations that sign a user in (signIn
# and signInWithPasskey), so both return the same payload and refuse the same
# accounts.
module Mutations::Auth::SignInPayload
  extend ActiveSupport::Concern

  included do
    field :token, String, null: true, description: "JWT authentication token."
    field :user_id, GraphQL::Types::ID, null: true, description: "The authenticated user's ID."
    field :username, String, null: true, description: "The authenticated user's username."
    field :slug, String, null: true, description: "The authenticated user's slug."
    field :role, String, null: true, description: "The authenticated user's role."
    field :email, String, null: true, description: "The authenticated user's email address."
    field :avatar_url, String, null: true, description: "URL for the authenticated user's small avatar. `null` if they have the default avatar or sign in failed."
    field :errors, [String], null: false, description: "Error messages if sign in failed."
  end

  private

  # The payload for a user who passed authentication: an error if their
  # account can't sign in, otherwise a fresh JWT and their details.
  def sign_in(user)
    return sign_in_failure("Your account has been banned.") if user.banned?
    return sign_in_failure("You must confirm your email address before signing in.") unless user.confirmed?

    {
      token: JwtService.encode(user),
      user_id: user.id,
      username: user.username,
      slug: user.slug,
      role: user.role,
      email: user.email,
      avatar_url: user.sized_avatar(:small)&.url,
      errors: []
    }
  end

  def sign_in_failure(message)
    { token: nil, user_id: nil, username: nil, slug: nil, role: nil, email: nil, avatar_url: nil, errors: [message] }
  end
end
