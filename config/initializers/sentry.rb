# frozen_string_literal: true

SENTRY_SENSITIVE_HEADERS = %w[authorization cookie x-user-email x-user-token].freeze

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN_RAILS']
  # Only run in production.
  config.enabled_environments = ['production']
  config.environment = Rails.env
  config.release = ENV['GIT_COMMIT_SHA']
  # Never send request bodies, cookies, IP addresses, or the Authorization
  # header to Sentry. GraphQL request bodies for signIn/updatePassword/
  # updateEmail contain plaintext passwords, and the Authorization header
  # carries live JWTs and OAuth tokens. The user's id and username are still
  # attached via Sentry.set_user in ApplicationController#set_sentry_context.
  config.send_default_pii = false

  # sentry-ruby still forwards every other request header even with
  # send_default_pii disabled, so strip the API token auth headers too.
  config.before_send = lambda do |event, _hint|
    headers = event.request&.headers
    headers&.reject! { |key, _| SENTRY_SENSITIVE_HEADERS.include?(key.to_s.downcase) }
    event
  end

  # Enable sending logs to Sentry
  config.enable_logs = true
  # Patch Ruby logger to forward logs
  config.enabled_patches = [:logger]

  config.rails.structured_logging.enabled = true

  config.rails.structured_logging.subscribers = {
    active_record: Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }
end
