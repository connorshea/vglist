namespace :deploy do
  desc "Deploys the latest code from the master branch into production"
  task production: :environment do
    # Pull down latest code.
    system('git pull')
    # Install dependencies with Bundler.
    system('bundle install --jobs=4 --without "test development"')
    # Install dependencies with yarn.
    system('yarn install --frozen-lockfile')
    # Migrate database.
    system('bundle exec rails db:migrate')
    # Compile CSS and JavaScript with Webpacker.
    system('bundle exec rails assets:precompile')

    puts "Deploy successful!"
    puts "Run 'sudo systemctl restart puma' to restart the puma server if necessary."
  end
end
