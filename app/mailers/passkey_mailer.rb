# frozen_string_literal: true

# Security notices about a user's passkeys.
class PasskeyMailer < ApplicationMailer
  # There's no shared mailer layout (Devise's emails use the gem's own views).
  layout false

  # Tells the user a passkey was added to their account, so they notice if
  # someone with access to their session added one of their own.
  def passkey_added
    @passkey = params[:passkey]
    @user = @passkey.user
    @settings_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173').chomp('/')}/settings/account"

    mail(to: @user.email, subject: 'A passkey was added to your vglist account')
  end
end
