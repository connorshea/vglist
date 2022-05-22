# typed: false
require 'rails_helper'

RSpec.describe "ConnectSteam Mutation API", type: :request do
  describe "Mutation creates the ExternalAccount" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!, $steamUsername: String!) {
          connectSteam(userId: $id, steamUsername: $steamUsername) {
            connected
          }
        }
      GRAPHQL
    end

    # Ensure we don't use a real Steam Web API Key in these tests.
    around(:each) do |example|
      with_environment('STEAM_WEB_API_KEY' => 'foo') do
        example.run
      end
    end

    context 'when the current user is an admin' do
      let!(:user) { create(:confirmed_admin) }
      let!(:user2) { create(:confirmed_user) }

      it "does not connect the other user's Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user2.id, steam_username: 'foobar' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to connect this user's Steam account.")
        end.not_to change(ExternalAccount, :count)
      end

      xit "can connect their own account" do
        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.graphql_dig(:connect_steam)).to eq(
            {
              connected: true
            }
          )
        end.to change(ExternalAccount, :count).by(1)
      end
    end

    context 'when the current user is a normal member' do
      let!(:user) { create(:confirmed_user) }
      let!(:user2) { create(:confirmed_user) }

      it "does not connect the other user's Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user2.id, steam_username: 'foobar' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to connect this user's Steam account.")
        end.not_to change(ExternalAccount, :count)
      end

      xit "they are able to connect their own Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.graphql_dig(:connect_steam)).to eq(
            {
              connected: true
            }
          )
        end.to change(ExternalAccount, :count).by(1)
      end
    end
  end
end
