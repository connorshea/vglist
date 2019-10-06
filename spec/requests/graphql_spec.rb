# typed: false
require 'rails_helper'

RSpec.describe "GraphQL", type: :request do
  describe "POST graphql_path" do
    let(:user) { create(:confirmed_user) }
    let(:application) { create(:application, owner: user) }
    let(:token) { create(:access_token, application: application, resource_owner: user) }

    it 'responds with http unauthorized if not authenticated' do
      post graphql_path(format: :json)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds with http success if you use an access token' do
      post graphql_path(format: :json, access_token: token.token)
      expect(response).to have_http_status(:success)
    end

    it 'responds with http success if user is logged in' do
      sign_in(user)
      post graphql_path(format: :json)
      expect(response).to have_http_status(:success)
    end
  end
end
