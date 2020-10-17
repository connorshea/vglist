# typed: strict
require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VideoGameList
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 6.0.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :forbidden

    # Allow cross-origin requests to GraphQL and ActiveStorage blobs.
    config.middleware.insert_before 0, Rack::Cors do
      T.unsafe(self).allow do
        T.unsafe(self).origins '*'
        T.unsafe(self).resource '/graphql', headers: :any, methods: [:post, :options]
        T.unsafe(self).resource '/rails/active_storage/*', headers: :any, methods: :get
      end
    end

    # Customize what the rails generate command creates.
    config.generators do |generate|
      # Disable helper generation
      generate.helper false
      # Disable CSS and JavaScript generation
      generate.assets false
      # Disable controller spec generation
      generate.controller_specs false
    end

    # Get the current commit SHA for the Rails app. This will surely have some
    # sort of negative side-effect I haven't figured out yet. This is used for
    # caching to make sure the cache is busted when a new version of the
    # application is deployed.
    # https://brandonhilkert.com/blog/understanding-the-rails-cache-id-environment-variable/
    ENV['GIT_COMMIT_SHA'] = `git rev-parse --short HEAD`.strip

    # Configure Sentry.
    Raven.configure do |config|
      config.dsn = ENV['SENTRY_DSN_RAILS']
      # Only run in production.
      config.environments = ['production']
      config.release = ENV['GIT_COMMIT_SHA']
    end

    config.to_prepare do
      # Only Applications list
      T.unsafe(Doorkeeper::ApplicationsController).layout "application"

      # Only Authorization endpoint
      T.unsafe(Doorkeeper::AuthorizationsController).layout "application"

      # Only Authorized Applications
      T.unsafe(Doorkeeper::AuthorizedApplicationsController).layout "application"
    end

    # Add spec to the directories that 'rails notes' checks.
    config.annotations.register_directories("spec")
    # Add .vue files to the file extensions picked up by 'rails notes'.
    config.annotations.register_extensions("vue") { |annotation| %r{//\s*(#{annotation}):?\s*(.*)$} }
  end
end
