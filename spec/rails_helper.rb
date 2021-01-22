# typed: false
# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rails'
require 'selenium/webdriver'
require 'webdrivers'
require 'paper_trail/frameworks/rspec'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Add FactoryBot support to Rspec tests.
  config.include FactoryBot::Syntax::Methods

  # Add Devise helpers to controller and view tests.
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :feature

  config.include FeatureTestHelper, type: :feature
  config.include ApiRequestTestHelper, type: :request

  # Prints JavaScript errors to the console if there are any.
  if ENV['RSPEC_FEATURE_DEBUG']
    config.after(:each, type: :feature, js: true) do
      errors = page.driver.browser.manage.logs.get(:browser)
      if errors.present?
        aggregate_failures 'javascript errrors' do
          errors.each do |error|
            expect(error.level).not_to eq('SEVERE'), error.message
            next unless error.level == 'WARNING'

            warn 'WARN: javascript warning'
            warn error.message
          end
        end
      end
    end
  end
end

# Configure shoulda-matchers to work with rspec and all of rails.
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Capybara configuration
Capybara.server = :puma, { Silent: true }

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    options: options,
    service: Selenium::WebDriver::Service.chrome(args: { log_path: 'tmp/chrome.log' })
end

# Disable sandboxing in CI as the sandbox is wonky inside Docker containers.
Capybara.register_driver :ci_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    options: options,
    service: Selenium::WebDriver::Service.chrome(args: { log_path: 'tmp/chrome.log' })
end

# Show Chrome running the test suite when RSPEC_FEATURE_DEBUG is set.
if ENV['CI']
  Capybara.default_driver = :ci_chrome
elsif ENV['RSPEC_FEATURE_DEBUG']
  Capybara.default_driver = :chrome
else
  Capybara.default_driver = :headless_chrome
end

if ENV['CI']
  Capybara.javascript_driver = :ci_chrome
else
  # Use headless_chrome for any feature tests marked with js: true
  Capybara.javascript_driver = :headless_chrome
end
