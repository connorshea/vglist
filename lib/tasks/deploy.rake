namespace :deploy do
  desc "Deploys the latest code from the master branch into production"
  task production: :environment do
    # Pull down latest code.
    puts "Pulling down the latest code from master..."
    system('git pull')
    # Install dependencies with Bundler.
    puts "Installing Ruby dependencies..."
    system('bundle install --jobs=4 --without "test development"')
    # Install dependencies with yarn.
    puts "Installing JavaScript dependencies..."
    system('yarn install --frozen-lockfile')
    # Migrate database.
    puts "Migrating database..."
    system('bundle exec rails db:migrate')
    # Compile CSS and JavaScript with Webpacker.
    puts "Precompiling assets..."
    system('bundle exec rails assets:precompile')

    puts "Deploy successful!"
    puts "Run 'sudo systemctl restart puma' to restart the puma server if necessary."
  end
end
