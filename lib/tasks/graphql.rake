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
