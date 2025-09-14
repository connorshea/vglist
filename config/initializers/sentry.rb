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

  config.rails.structured_logging.enabled = true

  config.rails.structured_logging.subscribers = {
    active_record: Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }
end
