# typed: false
namespace :rebuild do
  desc "Rebuild all pg_search indices."
  task 'multisearch:all': :environment do
    puts "Rebuilding pg_search multisearch indices for all models."
    %w[Companies Engines Games Genres Platforms Series].each do |model|
      puts "Rebuilding #{model} index..."
      Rake::Task['pg_search:multisearch:rebuild'].invoke(model)
    end
  end
end
