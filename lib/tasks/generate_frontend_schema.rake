# typed: false
# Generate the GraphQL schema, copy it to vglist-frontend, and generate the
# TypeScript type signatures.
namespace :graphql do
  desc "Generate the GraphQL schema, copy it over to the vglist-frontend repo, and generate TypeScript type signatures."
  task copy_to_frontend: :environment do
    # Invoke the Rake task to generate the GraphQL schema.
    Rake::Task['graphql:schema:dump'].invoke

    # Error out if no vglist-frontend sister directory exists.
    raise StandardError, 'No sister vglist-frontend directory could be found.' unless Dir.exist?('../vglist-frontend')


    # Copy schema.graphql to vglist-frontend sister directory.
    FileUtils.cp(Rails.root.join('schema.graphql'), '../vglist-frontend')

    # Use the `yarn run generate` command in vglist-frontend to generate
    # the TypeScript types.
    Dir.chdir('../vglist-frontend') do
      system('yarn run generate')
    end
  end
end
