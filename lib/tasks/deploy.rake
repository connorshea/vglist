# typed: false
namespace :deploy do
  desc "Deploys the latest code from the master branch into production"
  task production: :environment do
    Bundler.with_unbundled_env do
      # Pull down latest code.
      puts
      puts "Pulling down the latest code from master..."
      system('git pull')

      # Create Sentry release
      puts
      puts "Creating Sentry release..."
      version = `sentry-cli releases propose-version`.strip
      system("sentry-cli releases new -p vglist-backend -p vglist-frontend #{version}")
      system("sentry-cli releases set-commits --auto #{version}")

      # Install dependencies with Bundler.
      puts
      puts "Installing Ruby dependencies..."
      # Set the bundler configuration so it doesn't install development or test dependencies.
      system('bundle config set without "development test"')
      system('bundle install --jobs=4 --retry=3')

      # Install dependencies with yarn.
      puts
      puts "Installing JavaScript dependencies..."
      system('yarn install --frozen-lockfile')

      # Migrate database.
      puts
      puts "Migrating database..."
      system('bundle exec rails db:migrate')

      # Compile CSS and JavaScript with Webpacker.
      puts
      puts "Precompiling assets..."
      system('bundle exec rails assets:precompile')

      # Finalize Sentry release
      puts
      puts "Finalizing Sentry release..."
      system("sentry-cli releases finalize #{version}")

      puts
      puts "Deploy successful!"
      puts "Run 'sudo systemctl restart puma' to restart the puma server if necessary."
    end
  end
end
