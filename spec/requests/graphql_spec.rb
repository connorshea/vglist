# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:user) { create(:confirmed_user) }

    # API tokens were removed along with the public API, so the old
    # X-User-Email/X-User-Token headers must no longer authenticate anyone.
    it "ignores the removed API token headers" do
      headers = {
        'X-User-Email': user.email,
        'X-User-Token': SecureRandom.alphanumeric(40)
      }

      post graphql_path(format: :json), params: { query: '{ currentUser { id } }' }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig('data', 'currentUser')).to be_nil
    end

    it 'allows unauthenticated requests (for signIn/signUp mutations)' do
      query = '{ __typename }'
      post graphql_path(format: :json), params: { query: query }
      expect(response).to have_http_status(:success)
    end

    it 'authenticates with a valid JWT token' do
      jwt_token = JwtService.encode(user)
      headers = {
        'User-Agent': 'GraphQL Test',
        'Authorization': "Bearer #{jwt_token}"
      }
      query = '{ currentUser { id } }'

      post graphql_path(format: :json), params: { query: query }, headers: headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.dig('data', 'currentUser', 'id')).to eq(user.id.to_s)
    end

    # OAuth was removed along with the public API, so an old OAuth access
    # token (not a JWT) must not authenticate anyone.
    it 'treats a non-JWT bearer token as unauthenticated' do
      post graphql_path(format: :json),
        params: { query: '{ currentUser { id } }' },
        headers: { 'Authorization': "Bearer #{SecureRandom.hex(32)}" }

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig('data', 'currentUser')).to be_nil
    end

    it 'treats an expired JWT as unauthenticated' do
      expired_token = JWT.encode(
        { user_id: user.id, exp: 1.day.ago.to_i, iat: 2.days.ago.to_i },
        Rails.application.secret_key_base,
        'HS256'
      )
      query = '{ currentUser { id } }'

      post graphql_path(format: :json),
        params: { query: query },
        headers: { 'Authorization': "Bearer #{expired_token}" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.dig('data', 'currentUser')).to be_nil
    end

    it 'treats an invalid JWT as unauthenticated' do
      query = '{ currentUser { id } }'

      post graphql_path(format: :json),
        params: { query: query },
        headers: { 'Authorization': "Bearer invalid.jwt.token" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.dig('data', 'currentUser')).to be_nil
    end

    it 'treats a revoked JWT as unauthenticated' do
      jwt_token = JwtService.encode(user)
      JwtService.revoke_all!(user)
      query = '{ currentUser { id } }'

      post graphql_path(format: :json),
        params: { query: query },
        headers: { 'Authorization': "Bearer #{jwt_token}" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.dig('data', 'currentUser')).to be_nil
    end

    it 'rejects a revoked JWT for mutations that require authentication' do
      jwt_token = JwtService.encode(user)
      JwtService.revoke_all!(user)

      mutation = <<~GQL
        mutation UpdateUser($bio: String) {
          updateUser(bio: $bio) {
            user { id }
            errors
          }
        }
      GQL

      post graphql_path(format: :json),
        params: { query: mutation, variables: { bio: "hacked" }.to_json },
        headers: { 'Authorization': "Bearer #{jwt_token}" }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to include("logged in")
      expect(user.reload.bio).not_to eq("hacked")
    end
  end
end
