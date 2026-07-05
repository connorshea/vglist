# frozen_string_literal: true

# If we're in development mode, configure the GraphQL RailsLogger gem.
if Rails.env.development?
  GraphQL::RailsLogger.configure do |config|
    config.skip_introspection_query = true
  end
end
