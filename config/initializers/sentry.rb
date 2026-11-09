# frozen_string_literal: true

SENTRY_SENSITIVE_HEADERS = %w[authorization cookie x-user-email x-user-token].freeze

# Share of requests and jobs that get a performance trace. Each trace counts
# every SQL query as a span against the monthly span quota, so watch usage
# if this is raised further. Override with SENTRY_TRACES_SAMPLE_RATE (0.0 to 1.0).
SENTRY_TRACES_SAMPLE_RATE = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', '0.25').to_f

# Decides which transactions are traced. Requests from the SPA carry the
# frontend's sampling decision in their sentry-trace header, so a page load
# traced in the browser is traced through the API too, and an untraced one
# isn't. The health check (App Platform probes it every few seconds, Sentry
# uptime every minute) is never traced, so it can't eat the quota.
SENTRY_TRACES_SAMPLER = lambda do |sampling_context|
  next 0.0 if sampling_context.dig(:env, 'PATH_INFO') == '/health'

  parent_sampled = sampling_context[:parent_sampled]
  next parent_sampled ? 1.0 : 0.0 unless parent_sampled.nil?

  SENTRY_TRACES_SAMPLE_RATE
end

# Share of traced transactions that also get a CPU profile, so slow requests
# show which code the time went to, not just which SQL ran. Relative to the
# trace sample rate: 1.0 profiles every traced transaction. Override with
# SENTRY_PROFILES_SAMPLE_RATE (0.0 to 1.0).
SENTRY_PROFILES_SAMPLE_RATE = ENV.fetch('SENTRY_PROFILES_SAMPLE_RATE', '1.0').to_f

# Response statuses whose transactions are never traced.
SENTRY_TRACE_IGNORE_STATUS_CODES = [(301..303), (305..399), (401..404)].freeze

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN_RAILS']
  # Only run in production.
  config.enabled_environments = ['production']
  config.environment = Rails.env
  config.release = ENV['GIT_COMMIT_SHA'].presence
  # Never send request bodies, cookies, IP addresses, or the Authorization
  # header to Sentry. GraphQL request bodies for signIn/updatePassword/
  # updateEmail contain plaintext passwords, and the Authorization header
  # carries live JWTs. The user's id and username are still
  # attached via Sentry.set_user in ApplicationController#set_sentry_context.
  config.send_default_pii = false

  config.traces_sampler = SENTRY_TRACES_SAMPLER

  # Vernier, not the default StackProf: Puma runs several threads per worker,
  # and Vernier samples all of them and shows time spent waiting for the GVL.
  config.profiler_class = Sentry::Vernier::Profiler
  config.profiles_sample_rate = SENTRY_PROFILES_SAMPLE_RATE

  # Don't trace redirects. sentry-ruby 7.1 started tracing 302s and 303s by
  # default; this is the 6.x default, so they don't use up the span quota.
  config.trace_ignore_status_codes = SENTRY_TRACE_IGNORE_STATUS_CODES

  # Ctrl+C on a rake task run by hand (e.g. in `doctl apps console`) raises
  # Interrupt, in the task and in any job it had in flight. That's not a
  # bug, so don't report it.
  config.excluded_exceptions += ['Interrupt']

  # sentry-ruby still forwards every other request header even with
  # send_default_pii disabled, so strip the API token auth headers too.
  config.before_send = lambda do |event, _hint|
    headers = event.request&.headers
    headers&.reject! { |key, _| SENTRY_SENSITIVE_HEADERS.include?(key.to_s.downcase) }
    event
  end

  # sentry-ruby 7 sends metrics by default and has no option to turn them off,
  # so drop every metric here. We don't use Sentry metrics.
  config.before_send_metric = ->(_metric) {}

  # Logs are sent to Sentry by default as of sentry-ruby 7.
  # Patch Ruby logger to forward logs
  config.enabled_patches = [:logger]

  config.rails.structured_logging.enabled = true

  # No ActiveRecord subscriber: it sends a log for every SQL query, which
  # used up the monthly log quota within a few days.
  config.rails.structured_logging.subscribers = {
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }
end
