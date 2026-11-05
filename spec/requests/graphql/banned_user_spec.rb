# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL banned user enforcement", type: :request do
  let(:banned_user) { create(:banned_user) }
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

    expect(response).to have_http_status(:forbidden)
    json = JSON.parse(response.body)
    expect(json['errors'].first['message']).to eq("The user that owns this token has been banned.")
  end
end
