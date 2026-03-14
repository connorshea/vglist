class Mutations::Auth::RequestPasswordResetMutation < GraphQL::Schema::Mutation
  description "Request a password reset email."

  argument :email, String, required: true, description: "The email address associated with the account."

  field :message, String, null: false, description: "Status message."

  def resolve(email:)
    # Always return a success message to avoid leaking whether an email exists.
    User.send_reset_password_instructions(email: email)
    { message: "If an account with that email exists, password reset instructions have been sent." }
  end
end
