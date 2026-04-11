# frozen_string_literal: true

class Mutations::Auth::RequestPasswordResetMutation < GraphQL::Schema::Mutation
  description "Request a password reset email."

  argument :email, String, required: true, description: "The email address associated with the account."

  field :message, String, null: false, description: "Status message."

  def resolve(email:)
    # Always return a success message to avoid leaking whether an email exists.
    #
    # NOTE: There is a minor timing side-channel here — the "email exists"
    # path (token generation + mail delivery) is slower than a failed lookup.
    # A proper fix requires async processing (e.g. ActiveJob), which this
    # project does not currently use. The risk is low: an attacker can only
    # infer whether an email is registered, not gain access.
    User.send_reset_password_instructions(email: email)
    { message: "If an account with that email exists, password reset instructions have been sent." }
  end
end
