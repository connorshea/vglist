task stats: "vglist:stats"

# TODO: Remove this when Rails 6 comes out, as this is added to the stats
# directories there.
namespace :vglist do
  task :stats do
    require 'rails/code_statistics'
    ::STATS_DIRECTORIES << ["JavaScript", "app/javascript"]
  end
end
