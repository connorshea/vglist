source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.5'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.5'

# Use Puma as the app server
gem 'puma', '~> 6.3'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.4.0'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'

# Use devise for Users and authentication.
gem 'devise', '~> 4.9'

# Use kaminari for pagination.
gem 'kaminari', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Pundit for access control.
gem 'pundit', '~> 2.3'

# Postgres Search
gem 'pg_search', '~> 2.3'

# Image transformation
gem 'image_processing', '~> 1.12'

# Validations for ActiveStorage.
gem 'active_storage_validations', '~> 1.0.3'

# Generate URL slugs for models, e.g. '/users/spiderman'.
gem 'friendly_id', '~> 5.5.0'

# Use SPARQL for querying Wikidata in imports.
gem 'sparql', '~> 3.2.5', require: false

# Use Addressable for use with the Wikidata API.
gem 'addressable', '~> 2.8.4', require: false

# Use the AWS SDK S3 gem for DigitalOcean Spaces - which are S3-compatible.
gem 'aws-sdk-s3', '~> 1.66', require: false

# A CLI progress bar for use with the import rake tasks.
gem 'ruby-progressbar', '~> 1.13', require: false

# Use Sentry for error tracking in production.
gem 'sentry-ruby', '~> 5.9.0'
gem 'sentry-rails', '~> 5.9.0'

# Sorbet runtime typechecker and Sorbet Rails.
gem 'sorbet-runtime', '~> 0.5'

# GraphQL API https://github.com/rmosolgo/graphql-ruby
gem 'graphql', '~> 2.0.22'

# Doorkeeper for OAuth API tokens
gem "doorkeeper", "~> 5.5.4"

# Rack::Cors for handling CORS in API requests.
gem "rack-cors", "~> 2.0"

# Render SVGs inline using Webpacker.
gem 'inline_svg', '~> 1.9'

# Honeypot for spambots that doesn't require the user to actually do any
# captcha and doesn't use google stuff.
gem 'invisible_captcha', '~> 2.1.0'

# For parallel execution of long-running tasks.
gem 'parallel', '~> 1.23', require: false

# For tracking changes to records.
gem 'paper_trail', '~> 14.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # Pry for debugging.
  gem 'pry', '~> 0.14'
  gem 'pry-rails', '~> 0.3'

  # Rubocop for linting
  gem 'rubocop', '~> 1.52', require: false

  # rubocop extensions
  gem 'rubocop-performance', '~> 1.18', require: false
  gem 'rubocop-rspec', '~> 2.22', require: false
  gem 'rubocop-rails', '~> 2.19', require: false

  # Database cleaner for cleaning the database after tests/before seeding.
  gem 'database_cleaner', '~> 2.0'

  # Rspec-rails for testing.
  gem 'rspec-rails', '~> 6.0'

  # Factory Bot for creating factories.
  gem 'factory_bot_rails', '~> 6.2'

  # Code coverage
  gem 'simplecov', '~> 0.22', require: false

  # Shoulda-matchers for writing better tests on models.
  gem 'shoulda-matchers', '5.3.0'

  # For generating fake seeding data.
  gem 'faker', '~> 3.2.0'

  # For better display of rspec test suite progress
  gem 'fuubar', '~> 2.5.1'

  # Pundit matchers for simplifying policy testing.
  gem 'pundit-matchers', '~> 2.3.0'

  # Sorbet typechecker
  gem 'sorbet', '~> 0.5'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '~> 4.2.0'
  gem 'listen', '~> 3.8'
  # Better error pages.
  gem 'better_errors', '~> 2.10'
  # For more useful BetterError error pages.
  gem 'binding_of_caller', '~> 1.0'
  # Open screenshots when they're taken with capybara.
  gem 'launchy', '~> 2.5'
  # Improve the formatting of GraphQL requests in the logs.
  # https://github.com/jetruby/graphql-rails_logger
  gem 'graphql-rails_logger', '~> 1.2.4'
  # Enable dotenv for local environment variables.
  gem 'dotenv-rails', '~> 2.8'
  # Tapioca for generating Sorbet RBI files.
  # Use a fork to fix this issue: https://github.com/Shopify/tapioca/issues/208
  gem 'tapioca', '~> 0.11.3'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver', '~> 4.10'
  # Easy installation and use of WebDriver clients for various browsers.
  gem 'webdrivers', '~> 5.2'
  # Mock network requests and prevent outgoing requests from occuring in the test suite.
  gem 'webmock', '~> 3.18'
end

# # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
