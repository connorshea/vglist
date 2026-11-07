# frozen_string_literal: true

class Mutations::Auth::SignInMutation < GraphQL::Schema::Mutation
  description "Sign in with email and password. Returns a JWT token for authenticating subsequent requests."

  argument :email, String, required: true, description: "The user's email address."
  argument :password, String, required: true, description: "The user's password."

  field :token, String, null: true, description: "JWT authentication token."
  field :user_id, ID, null: true, description: "The authenticated user's ID."
  field :username, String, null: true, description: "The authenticated user's username."
  field :slug, String, null: true, description: "The authenticated user's slug."
  field :role, String, null: true, description: "The authenticated user's role."
  field :avatar_url, String, null: true, description: "URL for the authenticated user's small avatar. `null` if they have the default avatar or sign in failed."
  field :errors, [String], null: false, description: "Error messages if sign in failed."

  def resolve(email:, password:)
    user = User.authenticate_with_password(email, password)

    return failure("Invalid email or password.") if user.nil?
    return failure("Your account has been banned.") if user.banned?
    return failure("You must confirm your email address before signing in.") unless user.confirmed?

    token = JwtService.encode(user)
    {
      token: token,
      user_id: user.id,
      username: user.username,
      slug: user.slug,
      role: user.role,
      avatar_url: user.sized_avatar(:small)&.url,
      errors: []
    }
  end

  private

  def failure(message)
    { token: nil, user_id: nil, username: nil, slug: nil, role: nil, avatar_url: nil, errors: [message] }
  end
end
