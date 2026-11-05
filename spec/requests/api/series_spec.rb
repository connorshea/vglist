# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Series API", type: :request do
  describe "Query for data on series" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }
    let(:series) { create(:series) }
    let(:series2) { create(:series) }

    it "returns basic data for series" do
      series
      query_string = <<-GRAPHQL
        query($id: ID!) {
          series(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: series.id }, token: access_token)

      expect(result.graphql_dig(:series)).to eq(
        {
          id: series.id.to_s,
          name: series.name
        }
      )
    end

    it "returns data for a series when searching" do
      series
      query_string = <<-GRAPHQL
        query($query: String!) {
          seriesSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: series.name }, token: access_token)

      expect(result.graphql_dig(:series_search, :nodes)).to eq(
        [{
          id: series.id.to_s,
          name: series.name
        }]
      )
    end

    it "returns data for series' when listing" do
      series
      series2
      query_string = <<-GRAPHQL
        query {
          seriesList {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:series_list, :nodes)).to contain_exactly(
        {
          id: series.id.to_s,
          name: series.name
        },
        {
          id: series2.id.to_s,
          name: series2.name
        }
      )
    end
  end

  describe "Listing series for the series index" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }
    let!(:zelda) { create(:series, name: "The Legend of Zelda", created_at: 3.days.ago) }
    let!(:metroid) { create(:series, name: "metroid", created_at: 1.day.ago) }
    let(:query_string) do
      <<-GRAPHQL
        query($sortBy: SeriesSort, $nameContains: String) {
          seriesList(sortBy: $sortBy, nameContains: $nameContains) {
            totalCount
            nodes {
              name
              gamesCount
              firstReleaseYear
              lastReleaseYear
            }
          }
        }
      GRAPHQL
    end

    before(:each) do
      create(:series, name: "Quake", created_at: 2.days.ago)
      create(:game, series: zelda, release_date: Date.new(1986, 2, 21))
      create(:game, series: zelda, release_date: Date.new(2023, 5, 12))
      create(:game, series: zelda, release_date: nil)
      create(:game, series: metroid, release_date: Date.new(2002, 11, 17))
    end

    def list(**variables)
      api_request(query_string, variables: variables, token: access_token).graphql_dig(:series_list)
    end

    it "returns each series' game count and release-year span" do
      expect(list(sortBy: "MOST_GAMES")[:nodes]).to eq(
        [
          { name: "The Legend of Zelda", gamesCount: 3, firstReleaseYear: 1986, lastReleaseYear: 2023 },
          { name: "metroid", gamesCount: 1, firstReleaseYear: 2002, lastReleaseYear: 2002 },
          { name: "Quake", gamesCount: 0, firstReleaseYear: nil, lastReleaseYear: nil }
        ]
      )
    end

    it "sorts by name ignoring case" do
      expect(list(sortBy: "NAME")[:nodes].pluck(:name)).to eq(["metroid", "Quake", "The Legend of Zelda"])
    end

    it "sorts by most recently added" do
      expect(list(sortBy: "RECENTLY_ADDED")[:nodes].pluck(:name)).to eq(["metroid", "Quake", "The Legend of Zelda"])
    end

    it "filters by name, ignoring case, and counts only the matches" do
      result = list(sortBy: "NAME", nameContains: "ZEL")

      expect(result[:totalCount]).to eq(1)
      expect(result[:nodes].pluck(:name)).to eq(["The Legend of Zelda"])
    end

    it "treats LIKE wildcards in the filter as plain text" do
      expect(list(nameContains: "%")[:nodes]).to eq([])
    end

    it "counts games for a single series too" do
      result = api_request(
        "query($id: ID!) { series(id: $id) { gamesCount firstReleaseYear lastReleaseYear } }",
        variables: { id: zelda.id },
        token: access_token
      )

      expect(result.graphql_dig(:series)).to eq({ gamesCount: 3, firstReleaseYear: 1986, lastReleaseYear: 2023 })
    end
  end
end
