# typed: false
require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:token) { SecureRandom.alphanumeric(20) }
    let(:user) { create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(token)) }
    let(:user_with_no_token) { create(:confirmed_user) }
    let(:token2) { SecureRandom.alphanumeric(20) }
    let(:user2) { create(:confirmed_user, encrypted_api_token: EncryptionService.encrypt(token2)) }

    it 'responds with http unauthorized if not authenticated' do
      post graphql_path(format: :json)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http success if you use an API token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email,
        'X-User-Token': user.api_token
      }

      expect(user.api_token).to eq(token)
      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:success)
    end

    it 'responds with http unauthorized if user is logged in but with no API token' do
      sign_in(user)
      post graphql_path(format: :json)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized if user uses an invalid token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email,
        'X-User-Token': 'foo'
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized if user uses an invalid token even if the user is logged in' do
      sign_in(user)

      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email,
        'X-User-Token': 'foo'
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user without token when passing empty string' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user_with_no_token.email,
        'X-User-Token': ''
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user without token when passing token value' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user_with_no_token.email,
        # This should be nil.
        'X-User-Token': user_with_no_token.api_token
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user without token when passing nil' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user_with_no_token.email,
        'X-User-Token': nil
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user passing no relevant headers' do
      user
      headers = {
        'User-Agent': 'GraphQL Test'
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for logged-in user passing no relevant headers' do
      sign_in(user)

      headers = {
        'User-Agent': 'GraphQL Test'
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user passing only email' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user passing only token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Token': user.api_token
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user passing invalid authorization value' do
      user
      headers = {
        'User-Agent': 'GraphQL Test',
        'Authorization': 'Bearer foo'
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http unauthorized for user using another\'s token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user2.email,
        'X-User-Token': user.api_token
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
