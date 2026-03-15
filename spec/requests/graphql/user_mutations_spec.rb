require 'rails_helper'

RSpec.describe "GraphQL User Mutations", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:jwt_token) { JwtService.encode(user) }
  let(:auth_headers) { { 'Authorization': "Bearer #{jwt_token}" } }

  describe "updateUser mutation" do
    let(:query) do
      <<~GQL
        mutation UpdateUser($bio: String) {
          updateUser(bio: $bio) {
            user { id bio }
            errors
          }
        }
      GQL
    end

    it "updates the user's bio", :aggregate_failures do
      post graphql_path, params: {
        query: query,
        variables: { bio: "Updated bio!" }.to_json
      }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'updateUser')
      expect(data['errors']).to be_empty
      expect(data['user']['bio']).to eq("Updated bio!")
      expect(user.reload.bio).to eq("Updated bio!")
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: {
        query: query,
        variables: { bio: "New bio" }.to_json
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "resetApiToken mutation" do
    let(:query) do
      <<~GQL
        mutation ResetApiToken {
          resetApiToken {
            apiToken
            errors
          }
        }
      GQL
    end

    it "generates a new API token", :aggregate_failures do
      post graphql_path, params: { query: query }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'resetApiToken')
      expect(data['errors']).to be_empty
      expect(data['apiToken']).to be_present
      expect(data['apiToken'].length).to eq(40)
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: { query: query }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end
  end

  describe "exportLibrary mutation" do
    let(:query) do
      <<~GQL
        mutation ExportLibrary {
          exportLibrary {
            libraryJson
            errors
          }
        }
      GQL
    end

    it "exports an empty library" do
      post graphql_path, params: { query: query }, headers: auth_headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json.dig('data', 'exportLibrary')
      expect(data['errors']).to be_empty
      library = JSON.parse(data['libraryJson'])
      expect(library).to eq([])
    end

    it "exports a library with game purchases", :aggregate_failures do
      user_with_games = create(:user_with_game_purchase)
      user_with_games.confirm
      token = JwtService.encode(user_with_games)

      post graphql_path, params: { query: query }, headers: { 'Authorization': "Bearer #{token}" }

      json = JSON.parse(response.body)
      data = json.dig('data', 'exportLibrary')
      expect(data['errors']).to be_empty
      library = JSON.parse(data['libraryJson'])
      expect(library.length).to eq(1)
      expect(library.first).to have_key('game')
      expect(library.first['game']).to have_key('name')
    end

    it "returns an error when not authenticated" do
      post graphql_path, params: { query: query }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
    end

    it "returns an error when using a non-first-party API token" do
      api_token = SecureRandom.alphanumeric(20)
      api_token_user = create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(api_token))

      post graphql_path, params: { query: query }, headers: {
        'X-User-Email': api_token_user.email,
        'X-User-Token': api_token_user.api_token
      }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("first-party")
    end
  end
end
