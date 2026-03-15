require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:token) { SecureRandom.alphanumeric(20) }
    let(:user) { create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(token)) }
    let(:user_with_no_token) { create(:confirmed_user) }
    let(:token2) { SecureRandom.alphanumeric(20) }
    let(:user2) { create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(token2)) }

    it 'responds with http success when using a valid API token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email,
        'X-User-Token': user.api_token
      }

      expect(user.api_token).to eq(token)
      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:success)
    end

    it 'allows unauthenticated requests (for signIn/signUp mutations)' do
      query = '{ __typename }'
      post graphql_path(format: :json), params: { query: query }
      expect(response).to have_http_status(:success)
    end

    it 'authenticates with a valid JWT token' do
      jwt_token = JWT.encode(
        { user_id: user.id, exp: 1.day.from_now.to_i, iat: Time.current.to_i },
        Rails.application.credentials.secret_key_base,
        'HS256'
      )
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

    it 'responds with http unauthorized when both Authorization and X-User-Email headers are sent without a valid token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'Authorization': 'Bearer fake',
        'X-User-Email': user.email
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
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
  end
end
