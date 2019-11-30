# typed: false
require "graphql/rake_task"

GraphQL::RakeTask.new(
  load_schema: ->(_task) {
    require File.expand_path("../../config/environment", __dir__)
    VideoGameListSchema
  },
  load_context: ->(_task) {
    { current_user: User.new(role: :admin), doorkeeper_scopes: ['read', 'write'] }
  }
)

namespace :graphql do
  desc "Generate Documentation for the GraphQL API."
  task :docs, [:output_dir] => :environment do |_task, args|
    args.with_defaults(output_dir: 'graphql-docs')
    require 'graphql-docs'

    GraphQLDocs.build(
      filename: 'schema.graphql',
      output_dir: args[:output_dir]
    )
  end
end
