# typed: false
require 'rails_helper'

RSpec.describe "Global Search API", type: :request do
  describe "Query for data" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with games' do
      let(:game1) { create(:game, name: 'Half-Life') }
      let(:game2) { create(:game_with_cover, name: 'Super Mario Galaxy', developers: [create(:company, name: 'Nintendo')], release_date: 1.day.ago) }
      let(:games) { create_list(:game, 10, name: 'Portal') }

      it "returns basic data" do
        game1
        games
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              ... on GameSearchResult {
                id
                searchableId
                content
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Portal' }, token: access_token)

        expect(result.graphql_dig(:global_search).length).to eq(10)
        expect(result.graphql_dig(:global_search).pluck(:searchableId)).to eq(games.pluck(:id).map(&:to_s))
        expect(result.graphql_dig(:global_search).pluck(:content)).to eq(Array.new(10) { 'Portal' })
      end

      it "returns cover, release date, and developer" do
        game2
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              ... on GameSearchResult {
                searchableId
                content
                coverUrl
                releaseDate
                developerName
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Super Mario Gala' }, token: access_token)

        cover_variant = game2.sized_cover(:small)

        expect(result.graphql_dig(:global_search)).to eq(
          [
            {
              searchableId: game2.id.to_s,
              content: 'Super Mario Galaxy',
              coverUrl: Rails.application.routes.url_helpers.rails_representation_url(cover_variant),
              releaseDate: 1.day.ago.strftime("%F"),
              developerName: 'Nintendo'
            }
          ]
        )
      end
    end

    context 'with users' do
      let!(:user) { create(:user_with_avatar, username: 'among.us.fan') }

      it "returns avatar and slug" do
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              ... on UserSearchResult {
                searchableId
                content
                avatarUrl
                slug
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'among' }, token: access_token)

        avatar_variant = user.sized_avatar(:small)

        expect(result.graphql_dig(:global_search)).to eq(
          [
            {
              searchableId: user.id.to_s,
              content: 'among.us.fan',
              avatarUrl: Rails.application.routes.url_helpers.rails_representation_url(avatar_variant),
              slug: 'among-us-fan'
            }
          ]
        )
      end
    end

    context 'with all types of records' do
      let!(:company) { create(:company, name: 'Foo') }
      let!(:engine) { create(:engine, name: 'Foo') }
      let!(:game) { create(:game, name: 'Foo') }
      let!(:genre) { create(:genre, name: 'Foo') }
      let!(:platform) { create(:platform, name: 'Foo') }
      let!(:series) { create(:series, name: 'Foo') }
      let!(:user) { create(:user, username: 'Foo') }

      it "returns basic data" do
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              ... on GameSearchResult {
                searchableId
                content
              }
              ... on UserSearchResult {
                searchableId
                content
              }
              ... on PlatformSearchResult {
                searchableId
                content
              }
              ... on SeriesSearchResult {
                searchableId
                content
              }
              ... on GenreSearchResult {
                searchableId
                content
              }
              ... on EngineSearchResult {
                searchableId
                content
              }
              ... on CompanySearchResult {
                searchableId
                content
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Foo' }, token: access_token)

        expect(result.graphql_dig(:global_search).length).to eq(7)
        expect(result.graphql_dig(:global_search)).to eq(
          [
            {
              searchableId: company.id.to_s,
              content: company.name
            },
            {
              searchableId: engine.id.to_s,
              content: engine.name
            },
            {
              searchableId: game.id.to_s,
              content: game.name
            },
            {
              searchableId: genre.id.to_s,
              content: genre.name
            },
            {
              searchableId: platform.id.to_s,
              content: platform.name
            },
            {
              searchableId: series.id.to_s,
              content: series.name
            },
            {
              searchableId: user.id.to_s,
              content: user.username
            }
          ]
        )
      end
    end
  end
end
