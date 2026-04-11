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
  field :errors, [String], null: false, description: "Error messages if sign in failed."

  def resolve(email:, password:)
    user = User.find_by(email: email)

    return { token: nil, user_id: nil, username: nil, slug: nil, role: nil, errors: ["Invalid email or password."] } unless user&.valid_password?(password)

    return { token: nil, user_id: nil, username: nil, slug: nil, role: nil, errors: ["Your account has been banned."] } if user.banned?

    return { token: nil, user_id: nil, username: nil, slug: nil, role: nil, errors: ["You must confirm your email address before signing in."] } unless user.confirmed?

    token = JwtService.encode(user)
    { token: token, user_id: user.id, username: user.username, slug: user.slug, role: user.role, errors: [] }
  end
end
