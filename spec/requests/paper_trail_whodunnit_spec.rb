# frozen_string_literal: true

require 'rails_helper'

# The SPA authenticates with a JWT rather than a Devise session, so
# `current_user` has to come from the bearer token for PaperTrail to record
# who made a change.
RSpec.describe "PaperTrail whodunnit", type: :request, versioning: true do
  let(:user) { create(:confirmed_moderator) }
  let(:query) do
    <<-GRAPHQL
      mutation($name: String!, $wikidataId: ID!) {
        createCompany(name: $name, wikidataId: $wikidataId) {
          company {
            id
          }
        }
      }
    GRAPHQL
  end

  it "records the JWT user on versions created through GraphQL", :aggregate_failures do
    post graphql_path,
      params: { query: query, variables: { name: 'Valve', wikidataId: 2283 }.to_json },
      headers: { 'Authorization': "Bearer #{JwtService.encode(user)}" }

    company = Company.find_by!(name: 'Valve')
    version = company.versions.last
    expect(version.whodunnit).to eq(user.username)
    expect(version.whodunnit_id).to eq(user.id)
  end
end
