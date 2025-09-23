source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1.3'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'

# Use Puma as the app server
gem 'puma', '~> 7.0'

# Asset pipeline
gem 'propshaft', '~> 1.2'

# Use jsbundling-rails to bundle JavaScript using webpack
gem 'jsbundling-rails', '~> 1.3'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.14'

# Use devise for Users and authentication.
gem 'devise', '~> 4.9'

# Use kaminari for pagination.
gem 'kaminari', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Pundit for access control.
gem 'pundit', '~> 2.5'

# Postgres Search
gem 'pg_search', '~> 2.3'

# Image transformation
gem 'image_processing', '~> 1.14'

# Validations for ActiveStorage.
gem 'active_storage_validations', '~> 3.0.2'

# Generate URL slugs for models, e.g. '/users/spiderman'.
gem 'friendly_id', '~> 5.5.1'

# Use SPARQL for querying Wikidata in imports.
gem 'sparql', '~> 3.3.2', require: false

# Use Addressable for use with the Wikidata API.
gem 'addressable', '~> 2.8.6', require: false

# Use the AWS SDK S3 gem for DigitalOcean Spaces - which are S3-compatible.
gem 'aws-sdk-s3', '~> 1.66', require: false

# A CLI progress bar for use with the import rake tasks.
gem 'ruby-progressbar', '~> 1.13', require: false

# Use Sentry for error tracking in production.
gem 'sentry-ruby', '~> 5.27.1'
gem 'sentry-rails', '~> 5.27.0'

# GraphQL API https://github.com/rmosolgo/graphql-ruby
gem 'graphql', '~> 2.5.12'

# Doorkeeper for OAuth API tokens
gem "doorkeeper", "~> 5.8.2"

# Rack::Cors for handling CORS in API requests.
gem "rack-cors", "~> 3.0"

# Render SVGs inline using the asset pipeline.
gem 'inline_svg', '~> 1.10'

# Honeypot for spambots that doesn't require the user to actually do any
# captcha and doesn't use google stuff.
gem 'invisible_captcha', '~> 2.1.0'

# For parallel execution of long-running tasks.
gem 'parallel', '~> 1.27', require: false

# For tracking changes to records.
gem 'paper_trail', '~> 16.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :windows]

  # Pry for debugging.
  gem 'pry', '~> 0.15'
  gem 'pry-rails', '~> 0.3'

  # Rubocop for linting
  gem 'rubocop', '~> 1.80', require: false

  # rubocop extensions
  gem 'rubocop-performance', '~> 1.26.0', require: false
  gem 'rubocop-rspec', '~> 3.7.0', require: false
  gem 'rubocop-rspec_rails', '~> 2.31', require: false
  gem 'rubocop-capybara', '~> 2.22', require: false
  gem 'rubocop-factory_bot', '~> 2.27', require: false
  gem 'rubocop-rails', '~> 2.33', require: false

  # Database cleaner for cleaning the database after tests/before seeding.
  gem 'database_cleaner', '~> 2.1'

  # Rspec-rails for testing.
  gem 'rspec-rails', '~> 7.1'

  # Factory Bot for creating factories.
  gem 'factory_bot_rails', '~> 6.5'

  # Code coverage
  gem 'simplecov', '~> 0.22', require: false

  # Shoulda-matchers for writing better tests on models.
  gem 'shoulda-matchers', '6.5.0'

  # For generating fake seeding data.
  gem 'faker', '~> 3.5.2'

  # For better display of rspec test suite progress
  gem 'fuubar', '~> 2.5.1'

  # Pundit matchers for simplifying policy testing.
  gem 'pundit-matchers', '~> 4.0.0'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '~> 4.2.1'
  gem 'listen', '~> 3.9'
  # Better error pages.
  gem 'better_errors', '~> 2.10'
  # For more useful BetterError error pages.
  gem 'binding_of_caller', '~> 1.0'
  # Open screenshots when they're taken with capybara.
  gem 'launchy', '~> 3.1'
  # Improve the formatting of GraphQL requests in the logs.
  # https://github.com/jetruby/graphql-rails_logger
  gem 'graphql-rails_logger', '~> 1.2.5'
  # Enable dotenv for local environment variables.
  gem 'dotenv-rails', '~> 3.1'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver', '~> 4.35'
  # Mock network requests and prevent outgoing requests from occuring in the test suite.
  gem 'webmock', '~> 3.25'
  # Retry failed tests to reduce flakiness.
  gem 'rspec-retry', '~> 0.6.2'
end
