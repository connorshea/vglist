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

    token = generate_jwt(user)
    { token: token, user: user, errors: [] }
  end

  private

  def generate_jwt(user)
    payload = {
      user_id: user.id,
      exp: 30.days.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end
end
