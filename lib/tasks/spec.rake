namespace :spec do
  desc "Run the rspec test suite without the feature specs."
  task fast: :environment do
    puts 'bundle exec rspec --exclude-pattern "spec/features/**/*_spec.rb"'
    system('bundle exec rspec --exclude-pattern "spec/features/**/*_spec.rb"')
  end
end
