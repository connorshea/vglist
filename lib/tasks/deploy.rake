namespace :deploy do
  desc "Deploys the latest code from the main branch into production"
  task production: :environment do
    Bundler.with_unbundled_env do
      # Stash changes so the `git pull` will be guaranteed to work.
      puts
      puts "Stashing any changes..."
      system('git stash')

      # Pull down latest code.
      puts
      puts "Pulling down the latest code from main..."
      system('git pull')

      # Create Sentry release.
      puts
      puts "Creating Sentry release..."
      version = `sentry-cli releases propose-version`.strip
      system("sentry-cli releases new -p vglist-backend -p vglist-frontend #{version}")
      system("sentry-cli releases set-commits --auto #{version}")

      # Install dependencies with Bundler.
      puts
      puts "Installing Ruby dependencies..."
      system('bundle config set without "development test"')
      system('bundle install --jobs=4 --retry=3')

      # Install frontend dependencies and build.
      puts
      puts "Installing JavaScript dependencies..."
      system('cd frontend && yarn install --frozen-lockfile')

      puts
      puts "Building frontend..."
      system('cd frontend && npx vite build')

      # Copy built frontend to public/ for Rails to serve.
      puts
      puts "Copying frontend build to public/..."
      system('rm -rf public/assets public/index.html')
      system('cp -r frontend/dist/* public/')

      # Migrate database.
      puts
      puts "Migrating database..."
      system('bundle exec rails db:migrate')

      # Finalize Sentry release.
      puts
      puts "Finalizing Sentry release..."
      system("sentry-cli releases finalize #{version}")
      system("sentry-cli releases deploys #{version} new -e #{ENV['RAILS_ENV']}")

      puts
      puts "Deploy successful!"
      puts "Run 'sudo systemctl restart puma' to restart the puma server if necessary."
    end
  end
end
