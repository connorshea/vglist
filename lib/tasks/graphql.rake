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
    puts 'Schema IDL moved to `app/views/static_pages/_graphql_schema.html.erb`.'
  end

  desc "Validates that the schema partial is up-to-date with the actual GraphQL schema"
  task 'schema:partial:validate': :environment do
    Rake::Task["graphql:schema:idl"].invoke
    abort('The schema saved at `app/views/static_pages/_graphql_schema.html.erb` differs from the schema returned by an introspection query. Please update the file to match any changes to the vglist GraphQL API.') \
      unless FileUtils.identical?(Rails.root.join('schema.graphql'), Rails.root.join('app/views/static_pages/_graphql_schema.html.erb'))
    puts "GraphQL Schema in `app/views/static_pages/_graphql_schema.html.erb` is up to date."
  end
end
