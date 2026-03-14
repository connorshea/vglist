class Mutations::Auth::SignInMutation < GraphQL::Schema::Mutation
  description "Sign in with email and password. Returns a JWT token for authenticating subsequent requests."

  argument :email, String, required: true, description: "The user's email address."
  argument :password, String, required: true, description: "The user's password."

  field :token, String, null: true, description: "JWT authentication token."
  field :user, Types::UserType, null: true, description: "The authenticated user."
  field :errors, [String], null: false, description: "Error messages if sign in failed."

  def resolve(email:, password:)
    user = User.find_by(email: email)

    unless user&.valid_password?(password)
      return { token: nil, user: nil, errors: ["Invalid email or password."] }
    end

    if user.banned?
      return { token: nil, user: nil, errors: ["Your account has been banned."] }
    end

    unless user.confirmed?
      return { token: nil, user: nil, errors: ["You must confirm your email address before signing in."] }
    end

    token = JwtService.encode(user)
    { token: token, user: user, errors: [] }
  end
end
