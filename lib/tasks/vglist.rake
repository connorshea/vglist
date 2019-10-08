task stats: "vglist:stats"

namespace :vglist do
  task :stats do
    require 'rails/code_statistics'
    ::STATS_DIRECTORIES << ["GraphQL", "app/graphql"]
  end
end
