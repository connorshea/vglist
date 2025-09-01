Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN_RAILS']
  # Only run in production.
  config.enabled_environments = ['production']
  config.environment = Rails.env
  config.release = ENV['GIT_COMMIT_SHA']
  config.send_default_pii = true

  # Enable sending logs to Sentry
  config.enable_logs = true
  # Patch Ruby logger to forward logs
  config.enabled_patches = [:logger]
end
