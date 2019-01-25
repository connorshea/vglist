task :stats => "continue_from_checkpoint:stats"

namespace :continue_from_checkpoint do
  task :stats do
    require 'rails/code_statistics'
    ::STATS_DIRECTORIES << ["JavaScript", "app/javascript"]
  end
end
