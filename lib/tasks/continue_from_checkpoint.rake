task stats: "continue_from_checkpoint:stats"

# TODO: Remove this when Rails 6 comes out, as this is added to the stats
# directories there.
namespace :continue_from_checkpoint do
  task :stats do
    require 'rails/code_statistics'
    ::STATS_DIRECTORIES << ["JavaScript", "app/javascript"]
  end
end
