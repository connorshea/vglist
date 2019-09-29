# typed: false

# If we're in development mode, configure the GraphQL RailsLogger gem.
if Rails.env.development?
  GraphQL::RailsLogger.configure do |config|
    config.skip_introspection_query = true
    # Use a theme that actually works on a light terminal background.
    config.theme = Rouge::Themes::Github.new
  end
end
