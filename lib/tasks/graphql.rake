# typed: ignore
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
  desc "Create an HTML file from the schema to be embedded inside GraphiQL"
  task 'schema:partial': :environment do
    Rake::Task["graphql:schema:idl"].invoke
    FileUtils.mv(Rails.root.join('schema.graphql'), Rails.root.join('app/views/static_pages/_graphql_schema.html.erb'))
    puts 'Schema IDL moved to app/views/static_pages/_graphql_schema.html.erb'
  end
end
