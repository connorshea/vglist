# typed: false
require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:user) { create(:confirmed_user, :api_token) }

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

      post graphql_path(format: :json, headers: headers)
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
      post graphql_path(format: :json, headers: headers)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
