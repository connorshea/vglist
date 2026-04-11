class Mutations::Auth::SignUpMutation < GraphQL::Schema::Mutation
  description "Create a new user account. The user must confirm their email before signing in."

  argument :username, String, required: true, description: "Desired username (3-20 characters)."
  argument :email, String, required: true, description: "The user's email address."
  argument :password, String, required: true, description: "The user's password (minimum 8 characters)."
  argument :password_confirmation, String, required: true, description: "Password confirmation (must match password)."

  field :message, String, null: true, description: "Success message."
  field :errors, [String], null: false, description: "Error messages if sign up failed."

  def resolve(username:, email:, password:, password_confirmation:)
    user = User.new(
      username: username,
      email: email,
      password: password,
      password_confirmation: password_confirmation
    )

    if user.save
      { message: "Account created successfully. Please check your email to confirm your account.", errors: [] }
    else
      { message: nil, errors: user.errors.full_messages }
    end
  end
end
