# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Add to Steam Blocklist Mutation API", type: :request do
  describe "Mutation creates the Steam blocklist entry" do
    let(:access_token) { JwtService.encode(user) }
    let(:query_string) do
      <<-GRAPHQL
        mutation ($name: String!, $steamAppId: Int!) {
          addToSteamBlocklist(name: $name, steamAppId: $steamAppId) {
            steamBlocklistEntry {
              name
              steamAppId
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }

      it "increases the number of Steam blocklist entries" do
        expect do
          api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)
        end.to change(SteamBlocklist, :count).by(1)
      end

      it "returns data about newly created blocklist entry" do
        result = api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)

        expect(result.graphql_dig(:add_to_steam_blocklist, :steam_blocklist_entry)).to eq(
          {
            name: 'foobar',
            steamAppId: 123
          }
        )
      end

      it "removes Unmatched Games entries for that Steam App ID" do
        create_list(:unmatched_game, 2, external_service_id: '123')
        other = create(:unmatched_game, external_service_id: '456')

        expect do
          api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)
        end.to change(UnmatchedGame, :count).by(-2)
        expect(UnmatchedGame.exists?(other.id)).to be(true)
      end

      it "removes the Steam App ID from the game that has it" do
        steam_app_id = create(:steam_app_id, app_id: 123)

        api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)

        expect(SteamAppId.exists?(steam_app_id.id)).to be(false)
      end

      it "keeps the Steam App ID and Unmatched Games entries when the app is already blocklisted" do
        create(:steam_app_id, app_id: 123)
        create(:steam_blocklist, steam_app_id: 123)
        create(:unmatched_game, external_service_id: '123')

        result = api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)

        expect(result.to_h['errors'].first['message']).to eq('Steam app has already been taken')
        expect(SteamAppId.where(app_id: 123).count).to eq(1)
        expect(UnmatchedGame.where(external_service_id: '123').count).to eq(1)
      end
    end
  end
end
