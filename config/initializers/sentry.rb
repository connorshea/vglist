# typed: strict
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN_RAILS']
  # Only run in production.
  config.enabled_environments = ['production']
  config.environment = Rails.env
  config.release = ENV['GIT_COMMIT_SHA']
  config.send_default_pii = true
end
