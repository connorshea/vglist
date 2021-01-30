# typed: false
namespace "pg_search" do
  desc "Rebuild all pg_search indices."
  task 'multisearch:rebuild:all': :environment do
    puts "Rebuilding pg_search multisearch indices for all models."
    %w[Companies Engines Games Genres Platforms Series Users].each do |model|
      puts "Rebuilding #{model} index..."
      PgSearch::Multisearch.rebuild(model.singularize.constantize)
    end
  end
end
