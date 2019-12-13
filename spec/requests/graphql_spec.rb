# typed: false
require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:user) { create(:confirmed_user, :authentication_token) }

    it 'responds with http unauthorized if not authenticated' do
      post graphql_path(format: :json)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http success if you use an authentication_token' do
      headers = {
        'User-Agent': 'GraphQL Test',
        'X-User-Email': user.email,
        'X-User-Token': user.authentication_token
      }

      post graphql_path(format: :json), headers: headers
      expect(response).to have_http_status(:success)
    end

    it 'responds with http success if user is logged in' do
      sign_in(user)
      post graphql_path(format: :json)
      expect(response).to have_http_status(:success)
    end
  end
end
