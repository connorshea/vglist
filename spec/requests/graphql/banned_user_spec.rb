require 'rails_helper'

RSpec.describe "GraphQL banned user enforcement", type: :request do
  let(:token) { SecureRandom.alphanumeric(20) }
  let(:banned_user) { create(:banned_user, encrypted_api_token: EncryptionService.encrypt(token)) }
  let(:jwt_token) { JwtService.encode(banned_user) }

  let(:mutation_query) do
    <<~GQL
      mutation UpdateUser($bio: String) {
        updateUser(bio: $bio) {
          user { id }
          errors
        }
      }
    GQL
  end

  it "rejects mutations from a banned user using JWT auth" do
    post graphql_path, params: {
      query: mutation_query,
      variables: { bio: "I am banned" }.to_json
    }, headers: { 'Authorization': "Bearer #{jwt_token}" }

    json = JSON.parse(response.body)
    # Banned JWT users are treated as unauthenticated
    expect(json['errors'].first['message']).to include("logged in")
  end

  it "rejects mutations from a banned user using API token auth" do
    post graphql_path, params: {
      query: mutation_query,
      variables: { bio: "I am banned" }.to_json
    }, headers: {
      'X-User-Email': banned_user.email,
      'X-User-Token': banned_user.api_token
    }

    json = JSON.parse(response.body)
    # Banned API token users are treated as unauthenticated
    expect(json['errors'].first['message']).to include("logged in")
  end
end
