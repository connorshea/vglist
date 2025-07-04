namespace :import do
  require 'net/http'

  desc "Runs a full import of companies, engines, genres, platforms, series, games, and optionally covers."
  task :full, [:include_covers] => :environment do |_task, args|
    args.with_defaults(include_covers: false)

    puts 'Running a full import...'
    import_tasks = [
      "import:wikidata:companies",
      "import:wikidata:engines",
      "import:wikidata:genres",
      "import:wikidata:platforms",
      "import:wikidata:series",
      "import:wikidata:games"
    ]

    # Only import covers if the :include_covers argument is true.
    import_tasks << "import:pcgamingwiki:covers" if args[:include_covers]

    import_tasks.each do |task|
      puts "Running 'rake #{task}'."
      Rake::Task[task].invoke
      puts
      puts '-------------------------'
      puts
    end

    puts "Import completed!"
    puts "Run 'bundle exec rake rebuild:multisearch:all' to rebuild all the multisearch indices, or nothing will show up in your search results!"
  end
end
