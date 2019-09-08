# typed: true
# Solution for muting the ActiveStorage logger from:
# https://stackoverflow.com/a/57108948/7143763
class ActiveStorageStfuLogFormatter
  def initialize
    # Suppress is an array of request uuids. Each listed uuid means no messages from this request.
    @suppress = []
  end

  def call(_severity, _datetime, _progname, message)
    # Get uuid, which we need to properly distinguish between parallel requests.
    # Also remove uuid information from log (that's why we match the rest of message)
    matches = /\[([0-9a-zA-Z\-_]+)\] (.*)/m.match(message)

    # Return message as it is (including new line at the end)
    return "#{message}\n" unless matches

    uuid = matches[1]
    message = matches[2]

    if @suppress.include?(uuid) && message&.start_with?("Completed ")
      # Each request in Rails log ends with "Completed ..." message, so do suppressed messages.
      @suppress.delete(uuid)
      return nil
    elsif message&.start_with?(
      "Processing by ActiveStorage::DiskController#show",
      "Processing by ActiveStorage::BlobsController#show",
      "Processing by ActiveStorage::RepresentationsController#show",
      "Started GET \"/rails/active_storage/disk/",
      "Started GET \"/rails/active_storage/blobs/",
      "Started GET \"/rails/active_storage/representations/"
    )
      # When we use ActiveStorage disk provider, there are three types of request: Disk requests, Blobs requests and Representation requests.
      # These three types we would like to hide.
      @suppress << uuid
      return nil
    elsif !@suppress.include?(uuid)
      # All messages, which are not suppressed, print. New line must be added here.
      return "#{message}\n"
    end
  end
end

Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.after_initialize do
    Bullet.enable = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end

  # Faker gem configuration
  Faker::Config.locale = 'en'

  # Make ActiveStorage stfu
  config.log_tags = [:uuid]
  config.log_formatter = ActiveStorageStfuLogFormatter.new
end
