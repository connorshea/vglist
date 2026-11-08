# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "ConnectSteam Mutation API", type: :request do
  describe "Mutation creates the ExternalAccount" do
    let(:access_token) { JwtService.encode(user) }
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

    before(:each) do
      stub_request(:get, /api\.steampowered\.com/).to_return(
        status: 200,
        body: {
          'response': { 'steamid': '123' }
        }.to_json,
        headers: {}
      )
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

      it "can connect their own account" do
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

      it "they are able to connect their own Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.graphql_dig(:connect_steam)).to eq(
            {
              connected: true
            }
          )
        end.to change(ExternalAccount, :count).by(1)
      end

      it "escapes the username rather than letting it inject query parameters" do
        api_request(query_string, variables: { id: user.id, steam_username: 'foobar&key=attacker&format=xml' }, token: access_token)

        expect(WebMock).to have_requested(:get, 'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/')
          .with(query: { 'key' => 'foo', 'vanityurl' => 'foobar&key=attacker&format=xml' })
        expect(ExternalAccount.last.steam_profile_url).to eq('https://steamcommunity.com/id/foobar%26key%3Dattacker%26format%3Dxml/')
      end

      it "handles a non-ASCII username without raising" do
        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'connörshea' }, token: access_token)
          expect(result.graphql_dig(:connect_steam)).to eq(
            {
              connected: true
            }
          )
        end.to change(ExternalAccount, :count).by(1)

        expect(WebMock).to have_requested(:get, 'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/')
          .with(query: { 'key' => 'foo', 'vanityurl' => 'connörshea' })
      end

      it "returns an error when the Steam API returns a non-JSON response" do
        stub_request(:get, /api\.steampowered\.com/).to_return(
          status: 200,
          body: '<?xml version="1.0"?><response><steamid>123</steamid></response>',
          headers: {}
        )

        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq('The Steam API returned an unexpected response.')
        end.not_to change(ExternalAccount, :count)
      end

      it "returns an error when the Steam account is already connected to another user" do
        create(:external_account, user: user2, steam_id: 123)

        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq('That Steam account is already connected to another vglist account.')
        end.not_to change(ExternalAccount, :count)
      end

      it "accepts a full vanity profile URL" do
        result = api_request(query_string, variables: { id: user.id, steam_username: ' https://steamcommunity.com/id/foobar/ ' }, token: access_token)

        expect(result.graphql_dig(:connect_steam)).to eq({ connected: true })
        expect(WebMock).to have_requested(:get, 'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/')
          .with(query: { 'key' => 'foo', 'vanityurl' => 'foobar' })
        expect(ExternalAccount.last.steam_profile_url).to eq('https://steamcommunity.com/id/foobar/')
      end

      it "accepts a numeric profile URL without calling the Steam API" do
        result = api_request(query_string, variables: { id: user.id, steam_username: 'https://steamcommunity.com/profiles/76561197960287930/' }, token: access_token)

        expect(result.graphql_dig(:connect_steam)).to eq({ connected: true })
        expect(WebMock).not_to have_requested(:get, /api\.steampowered\.com/)
        expect(ExternalAccount.last).to have_attributes(
          steam_id: 76_561_197_960_287_930,
          steam_profile_url: 'https://steamcommunity.com/profiles/76561197960287930/'
        )
      end

      it "accepts a bare SteamID64 without calling the Steam API" do
        result = api_request(query_string, variables: { id: user.id, steam_username: '76561197960287930' }, token: access_token)

        expect(result.graphql_dig(:connect_steam)).to eq({ connected: true })
        expect(WebMock).not_to have_requested(:get, /api\.steampowered\.com/)
        expect(ExternalAccount.last.steam_id).to eq(76_561_197_960_287_930)
      end

      it "returns a clear error when Steam finds no matching username" do
        stub_request(:get, /api\.steampowered\.com/).to_return(
          status: 200,
          body: { 'response': { 'success': 42, 'message': 'No match' } }.to_json,
          headers: {}
        )

        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'nobody' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq('Unable to find a Steam account with the username "nobody".')
        end.not_to change(ExternalAccount, :count)
      end

      it "returns an error when the Steam API times out" do
        stub_request(:get, /api\.steampowered\.com/).to_timeout

        expect do
          result = api_request(query_string, variables: { id: user.id, steam_username: 'foobar' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq('The Steam API took too long to respond.')
        end.not_to change(ExternalAccount, :count)
      end
    end
  end
end
