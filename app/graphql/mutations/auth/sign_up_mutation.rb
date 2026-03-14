class Mutations::Auth::SignUpMutation < GraphQL::Schema::Mutation
  description "Create a new user account. The user must confirm their email before signing in."

  argument :username, String, required: true, description: "Desired username (3-20 characters)."
  argument :email, String, required: true, description: "The user's email address."
  argument :password, String, required: true, description: "The user's password (minimum 8 characters)."
  argument :password_confirmation, String, required: true, description: "Password confirmation (must match password)."

  field :user, Types::UserType, null: true, description: "The newly created user."
  field :errors, [String], null: false, description: "Error messages if sign up failed."

  def resolve(username:, email:, password:, password_confirmation:)
    user = User.new(
      username: username,
      email: email,
      password: password,
      password_confirmation: password_confirmation
    )

    if user.save
      { user: user, errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
