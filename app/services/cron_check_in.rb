# frozen_string_literal: true

# Reports each run of a scheduled task to a Sentry cron monitor, so Sentry
# alerts when a run fails, runs too long, or never starts. The monitor is
# created (or its schedule updated) from the first check-in, so there's
# nothing to set up in Sentry by hand.
#
# Does nothing outside production, where Sentry isn't sending events.
module CronCheckIn
  # App Platform scheduled jobs can take a few minutes to pull the image and
  # boot, so allow some slack before Sentry calls a run missed.
  CHECKIN_MARGIN_MINUTES = 15

  # Wraps the block in an in_progress check-in and an ok or error check-in.
  # Errors are re-raised so the job still fails (and Sentry still gets the
  # exception itself).
  #
  # @param slug [String] the monitor's slug in Sentry
  # @param crontab [String] the schedule, matching the job's cron in .do/app.yaml (UTC)
  # @param max_runtime [Integer] minutes before Sentry marks a run as timed out
  def self.wrap(slug, crontab:, max_runtime:)
    monitor_config = Sentry::Cron::MonitorConfig.from_crontab(
      crontab,
      timezone: 'UTC',
      checkin_margin: CHECKIN_MARGIN_MINUTES,
      max_runtime: max_runtime
    )
    check_in_id = Sentry.capture_check_in(slug, :in_progress, monitor_config: monitor_config)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = :error

    result = yield
    status = :ok
    result
  ensure
    if monitor_config
      Sentry.capture_check_in(
        slug,
        status,
        check_in_id: check_in_id,
        duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,
        monitor_config: monitor_config
      )
    end
  end
end
