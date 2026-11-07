# frozen_string_literal: true

# Rate limiting for the endpoints that handle credentials or send email:
# sign in, sign up, password reset, and confirmation resend. These exist both
# as REST endpoints (/api/auth/*, Devise's /users/*) and as GraphQL mutations.
#
# Throttle counters live in Rails.cache. In the test environment (and in
# development with caching disabled) that is a null store, so throttling is a
# no-op there unless a spec swaps in a real store.
module RackAttackConfig
  AUTH_MUTATION_PATTERN = /\b(signIn|signUp|requestPasswordReset|passkeyAuthenticationOptions|signInWithPasskey)\b/
  SIGN_IN_PATTERN = /\bsignIn\b/
  SIGN_UP_PATTERN = /\bsignUp\b/
  EMAIL_DELIVERY_MUTATION_PATTERN = /\b(signUp|requestPasswordReset)\b/

  # Devise and /api/auth endpoints, grouped by what an attacker gains from
  # hammering them.
  SIGN_IN_PATHS = %w[/api/auth/sign_in].freeze
  SIGN_UP_PATHS = %w[/api/auth/sign_up].freeze
  EMAIL_DELIVERY_PATHS = %w[/api/auth/sign_up /users/password /users/confirmation].freeze
  AUTH_PATHS = (SIGN_IN_PATHS + EMAIL_DELIVERY_PATHS).freeze

  # Avatar uploads, which store a file and generate variants.
  AVATAR_UPLOAD_PATHS = %w[/api/users/me/avatar].freeze

  module_function

  def graphql_request?(req)
    req.post? && path(req) == '/graphql'
  end

  def avatar_upload_request?(req)
    req.post? && AVATAR_UPLOAD_PATHS.include?(path(req))
  end

  def auth_request?(req)
    return false unless req.post? || req.put? || req.patch?

    AUTH_PATHS.include?(path(req)) || graphql_query(req).match?(AUTH_MUTATION_PATTERN)
  end

  def sign_in_request?(req)
    return false unless req.post?

    SIGN_IN_PATHS.include?(path(req)) || graphql_query(req).match?(SIGN_IN_PATTERN)
  end

  def sign_up_request?(req)
    return false unless req.post?

    SIGN_UP_PATHS.include?(path(req)) || graphql_query(req).match?(SIGN_UP_PATTERN)
  end

  def email_delivery_request?(req)
    return false unless req.post?

    EMAIL_DELIVERY_PATHS.include?(path(req)) || graphql_query(req).match?(EMAIL_DELIVERY_MUTATION_PATTERN)
  end

  # The path as the router sees it. Rack::Attack runs before routing, so the
  # raw path can differ from what we match against while still reaching the
  # same action: every route accepts an optional format suffix
  # (`/api/auth/sign_in.json`), and the router squeezes duplicate slashes and
  # ignores a trailing one (`//api/auth/sign_in/`).
  def path(req)
    req.env['vglist.rack_attack.path'] ||=
      ActionDispatch::Journey::Router::Utils.normalize_path(req.path).sub(%r{\.[^/.]+\z}, '')
  end

  # The client's IP address.
  #
  # Behind a proxy that puts the client IP in its own header, set
  # CLIENT_IP_HEADER to that header's name. DigitalOcean App Platform uses
  # `DO-Connecting-IP` and puts its ingress server, not the client, in
  # X-Forwarded-For, so without this every visitor would share the ingress's
  # counters. Only set it where the proxy always overwrites the header,
  # otherwise clients could pick their own IP.
  #
  # Otherwise, use the IP computed by ActionDispatch::RemoteIp (which knows
  # about trusted proxies) and fall back to Rack's best guess.
  def client_ip(req)
    header = ENV.fetch('CLIENT_IP_HEADER', nil)
    if header.present?
      forwarded = req.get_header("HTTP_#{header.upcase.tr('-', '_')}")
      return forwarded.strip if forwarded.present?
    end

    req.env['action_dispatch.remote_ip']&.to_s || req.ip
  end

  # The email the request is acting on, normalized so "Foo@Example.com " and
  # "foo@example.com" share a counter. Returns nil when there isn't one.
  def email(req)
    raw =
      if path(req) == '/graphql'
        graphql_email(req)
      elsif path(req).start_with?('/users/')
        dig_param(req, 'user', 'email')
      else
        dig_param(req, 'email')
      end

    raw = raw.to_s.strip.downcase
    raw.presence
  end

  def graphql_query(req)
    return '' unless path(req) == '/graphql'

    graphql_body(req)['query'].to_s
  end

  def graphql_email(req)
    body = graphql_body(req)
    variables = body['variables']
    variables = parse_json(variables) if variables.is_a?(String)
    return variables['email'] if variables.is_a?(Hash) && variables['email'].present?

    # Fall back to an inline literal, e.g. `signIn(email: "foo@example.com", ...)`.
    body['query'].to_s[/\bemail:\s*"([^"]*)"/, 1]
  end

  # Parse and memoize the GraphQL request body. graphql-request posts JSON,
  # which Rack::Request#params does not parse, so read the raw body and
  # rewind it for the app.
  def graphql_body(req)
    req.env['vglist.rack_attack.graphql_body'] ||=
      if req.media_type == 'application/json'
        raw = req.body&.read
        req.body&.rewind
        parsed = parse_json(raw)
        parsed.is_a?(Hash) ? parsed : {}
      else
        params = safe_params(req)
        params.is_a?(Hash) ? params : {}
      end
  end

  def dig_param(req, *keys)
    params = safe_params(req)
    return nil unless params.is_a?(Hash)

    value = params.dig(*keys)
    value.is_a?(String) ? value : nil
  rescue TypeError
    nil
  end

  def safe_params(req)
    req.params
  rescue StandardError
    {}
  end

  def parse_json(raw)
    return {} if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end
end

Rack::Attack.cache.store = Rails.cache

# Per-IP cap on all GraphQL requests, so a scraper can't page through the
# whole catalog as fast as the server will answer. Normal browsing sends a few
# requests per page, well under this. Counters live in Rails.cache, which is
# per Puma worker in production, so the effective limit is this times the
# number of workers. GRAPHQL_RATE_LIMIT overrides the per-minute limit.
Rack::Attack.throttle('graphql/ip', limit: ENV.fetch('GRAPHQL_RATE_LIMIT', 120).to_i, period: 1.minute) do |req|
  RackAttackConfig.client_ip(req) if RackAttackConfig.graphql_request?(req)
end

# Per-IP cap across every credential endpoint, so a single client can't
# spray guesses across many accounts or trigger unbounded email delivery.
Rack::Attack.throttle('auth/ip', limit: 20, period: 1.minute) do |req|
  RackAttackConfig.client_ip(req) if RackAttackConfig.auth_request?(req)
end

# Per-IP cap on sign-up attempts, much tighter than auth/ip because each
# successful one leaves a users row and sends a confirmation email. It counts
# attempts, not accounts: failed tries (taken username, short password,
# expired Turnstile token) count too, and so does everyone behind the same
# NAT. Turnstile is the main defense, so this is a backstop with room for a
# few fumbles. Like the others, the counter is per Puma worker (see the
# graphql/ip comment above), but don't count on that to loosen it.
Rack::Attack.throttle('sign_up/ip', limit: 10, period: 1.hour) do |req|
  RackAttackConfig.client_ip(req) if RackAttackConfig.sign_up_request?(req)
end

# Per-account cap on password guesses, regardless of source IP.
Rack::Attack.throttle('auth/sign_in/email', limit: 10, period: 5.minutes) do |req|
  RackAttackConfig.email(req) if RackAttackConfig.sign_in_request?(req)
end

# Per-address cap on emails we'll send (sign up, password reset,
# confirmation resend), to prevent mail-bombing a victim's inbox.
Rack::Attack.throttle('auth/email_delivery/email', limit: 5, period: 15.minutes) do |req|
  RackAttackConfig.email(req) if RackAttackConfig.email_delivery_request?(req)
end

# Per-IP cap on avatar uploads. Each one stores a file and generates three
# variants, so keep it well below anything a person would hit by retrying.
Rack::Attack.throttle('avatar_upload/ip', limit: 10, period: 1.minute) do |req|
  RackAttackConfig.client_ip(req) if RackAttackConfig.avatar_upload_request?(req)
end

Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env['rack.attack.match_data'] || {}
  period = match_data[:period].to_i
  retry_after = period.positive? ? (period - (Time.now.to_i % period)) : 60
  message = 'Too many requests. Please try again later.'

  [
    429,
    { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
    # Include both the REST (`error`) and GraphQL (`errors`) shapes so every
    # client renders the message.
    [{ error: message, errors: [{ message: message }] }.to_json]
  ]
end
