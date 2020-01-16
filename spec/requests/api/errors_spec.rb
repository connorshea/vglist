# typed: false
require 'rails_helper'

RSpec.describe "API Errors", type: :request do
  describe "Get " do
    let(:invalid_access_token) { instance_double("Doorkeeper::AccessToken", token: 'foo') }
    let(:banned_user) { create(:banned_user) }
    let(:application) { build(:application, owner: banned_user) }
    let(:banned_user_access_token) { create(:access_token, resource_owner_id: banned_user.id, application: application) }
    let(:game) { create(:game) }
    let(:query_string) do
      <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
          }
        }
      GRAPHQL
    end

    it "returns an error if an invalid access token is provided" do
      result = api_request(query_string, variables: { id: game.id }, token: invalid_access_token)

      expect(api_result_errors(result)).to include('The access token is invalid')
    end

    it "returns an error if banned user's access token is provided" do
      result = api_request(query_string, variables: { id: game.id }, token: banned_user_access_token)

      expect(api_result_errors(result)).to include('The user that owns this token has been banned.')
    end
  end
end
