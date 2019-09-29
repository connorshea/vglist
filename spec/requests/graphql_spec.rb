# typed: false
require 'rails_helper'

RSpec.describe "Graphql", type: :request do
  describe "POST graphql_path" do
    let(:user) { create(:confirmed_user) }
    let(:application) { create(:application, owner: user) }
    let(:token) { create(:access_token, application: application, resource_owner: user) }

    it 'responds with http success' do
      post graphql_path(format: :json, access_token: token.token)
      expect(response).to have_http_status(:success)
    end
  end
end
