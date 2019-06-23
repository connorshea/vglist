require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VideoGameList
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    # Customize what the rails generate command creates.
    config.generators do |generate|
      # Disable helper generation
      generate.helper false
      # Disable CSS and JavaScript generation
      generate.assets false
      # Disable controller spec generation
      generate.controller_specs false
    end

    if Rails.env.production?
      Raven.configure do |config|
        config.dsn = ENV['SENTRY_DSN']
      end
    end

    # Add spec to the directories that 'rails notes' checks.
    config.annotations.register_directories("spec")
    # Add .vue files to the file extensions picked up by 'rails notes'.
    config.annotations.register_extensions("vue") { |annotation| %r{//\s*(#{annotation}):?\s*(.*)$} }

    # Get the current commit SHA for the Rails app. This will surely have some
    # sort of negative side-effect I haven't figured out yet. This is used for
    # caching to make sure the cache is busted when a new version of the
    # application is deployed.
    # https://brandonhilkert.com/blog/understanding-the-rails-cache-id-environment-variable/
    ENV['GIT_COMMIT_SHA'] = `git rev-parse --short HEAD`.strip
  end
end
