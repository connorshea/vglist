# frozen_string_literal: true

class Mutations::Auth::SignInMutation < GraphQL::Schema::Mutation
  include Mutations::Auth::SignInPayload

  description "Sign in with email and password. Returns a JWT token for authenticating subsequent requests."

  argument :email, String, required: true, description: "The user's email address."
  argument :password, String, required: true, description: "The user's password."

  def resolve(email:, password:)
    user = User.authenticate_with_password(email, password)
    return sign_in_failure("Invalid email or password.") if user.nil?

    sign_in(user)
  end
end
