# frozen_string_literal: true

# WebAuthn (passkey) relying party settings.
#
# WebAuthn checks the origin of the page that calls `navigator.credentials`,
# which is the SPA, not the API host. So the allowed origin is FRONTEND_URL
# (https://vglist.co in production) and api.vglist.co plays no part.
#
# The RP ID is the domain passkeys are bound to. It defaults to FRONTEND_URL's
# host (`vglist.co` in production, `localhost` in development and test).
# Passkeys issued for an RP ID only ever work on that domain and its
# subdomains, so changing it later strands every existing passkey. Set
# WEBAUTHN_RP_ID only if FRONTEND_URL's host isn't the domain you want.
frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:5173').chomp('/')

WebAuthn.configure do |config|
  config.allowed_origins = [frontend_url]
  config.rp_id = ENV.fetch('WEBAUTHN_RP_ID') { URI.parse(frontend_url).host }
  config.rp_name = 'vglist'
  # Ceremonies time out in the browser after this long. Challenges expire on
  # the server after WebauthnChallenge::TTL, which is a bit longer.
  config.credential_options_timeout = 120_000
end
