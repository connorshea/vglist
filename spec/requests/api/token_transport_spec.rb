# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for the OAuth token transport. Doorkeeper's default
# `access_token_methods` also accepts `?access_token=`/`?bearer_token=` and the
# equivalent body fields, but GraphqlController only routes a request through
# `doorkeeper_authorize!` when the token arrives in the `Authorization` header.
# A parameter-borne token therefore used to authenticate its resource owner
# while skipping the scope, expiry and revocation checks entirely.
RSpec.describe "API token transport", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:application) { build(:application, owner: user) }
  let(:game) { create(:game) }

  let(:query) do
    <<-GRAPHQL
      query {
        currentUser {
          id
          username
        }
      }
    GRAPHQL
  end

  let(:mutation) do
    <<-GRAPHQL
      mutation($gameId: ID!) {
        addGameToLibrary(gameId: $gameId) {
          gamePurchase {
            id
          }
        }
      }
    GRAPHQL
  end

  def graphql_post(params)
    post graphql_path, params: params
    JSON.parse(response.body)
  end

  context 'with a read-only token' do
    let(:read_only_token) do
      create(:access_token, resource_owner_id: user.id, application: application, scopes: 'read')
    end

    it "rejects a mutation when the token is in the Authorization header" do
      result = api_request(mutation, variables: { game_id: game.id }, token: read_only_token)

      expect(result.to_h['errors'].first['message'])
        .to eq("Your token must have the 'write' scope to perform a mutation.")
      expect(GamePurchase.count).to eq(0)
    end

    it "does not authenticate a mutation when the token is a query parameter" do
      body = graphql_post(
        query: mutation,
        variables: { gameId: game.id }.to_json,
        access_token: read_only_token.token
      )

      expect(body.dig('data', 'addGameToLibrary')).to be_nil
      expect(body['errors']).to be_present
      expect(GamePurchase.count).to eq(0)
    end
  end

  context 'with a revoked token' do
    let(:revoked_token) do
      create(:access_token, resource_owner_id: user.id, application: application).tap(&:revoke)
    end

    it "rejects a query when the token is in the Authorization header" do
      result = api_request(query, token: revoked_token)

      expect(response).to have_http_status(:unauthorized)
      expect(result.to_h.dig('data', 'currentUser')).to be_nil
    end

    it "does not authenticate a query when the token is a query parameter" do
      body = graphql_post(query: query, access_token: revoked_token.token)

      expect(body.dig('data', 'currentUser')).to be_nil
    end

    it "does not authenticate a query when the token is a bearer_token parameter" do
      body = graphql_post(query: query, bearer_token: revoked_token.token)

      expect(body.dig('data', 'currentUser')).to be_nil
    end
  end

  context 'with a valid token passed as a parameter' do
    let(:access_token) do
      create(:access_token, resource_owner_id: user.id, application: application)
    end

    it "does not authenticate via the access_token parameter" do
      body = graphql_post(query: query, access_token: access_token.token)

      expect(body.dig('data', 'currentUser')).to be_nil
    end

    it "does not authenticate via the bearer_token parameter" do
      body = graphql_post(query: query, bearer_token: access_token.token)

      expect(body.dig('data', 'currentUser')).to be_nil
    end

    it "still authenticates via the Authorization header" do
      result = api_request(query, token: access_token)

      expect(result.graphql_dig(:current_user, :username)).to eq(user.username)
    end
  end
end
