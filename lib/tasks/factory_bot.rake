namespace :factory_bot do
  desc "Verify that all FactoryBot factories are valid"
  task lint: :environment do
    if Rails.env.test?
      DatabaseCleaner.clean_with(:deletion)
      DatabaseCleaner.cleaning do
        FactoryBot.lint
      end
    else
      puts "Please run this task with RAILS_ENV='test'!"
    end
  end
end
