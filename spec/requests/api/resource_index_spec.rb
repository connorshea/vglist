# frozen_string_literal: true

require 'rails_helper'

# The genre, platform, company and engine index pages. `series_spec.rb` covers
# seriesList.
RSpec.describe "Resource index API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }

  {
    genres: { model: :genre, join: :game_genre },
    platforms: { model: :platform, join: :game_platform },
    companies: { model: :company, join: :game_developer },
    engines: { model: :engine, join: :game_engine }
  }.each do |field, config|
    describe field.to_s do
      let(:query_string) do
        <<-GRAPHQL
          query($sortBy: ResourceSort, $nameContains: String) {
            #{field}(sortBy: $sortBy, nameContains: $nameContains) {
              totalCount
              nodes {
                name
                gamesCount
              }
            }
          }
        GRAPHQL
      end
      let!(:big) { create(config[:model], name: "Zeta", created_at: 3.days.ago) }
      let!(:small) { create(config[:model], name: "alpha", created_at: 1.day.ago) }

      before(:each) do
        create(config[:model], name: "Mu", created_at: 2.days.ago)
        create_list(config[:join], 2, config[:model] => big)
        create(config[:join], config[:model] => small)
      end

      define_method(:list) do |**variables|
        api_request(query_string, variables: variables, token: access_token).graphql_dig(field)
      end

      it "returns each record's game count, most games first" do
        expect(list(sortBy: "MOST_GAMES")[:nodes]).to eq(
          [{ name: "Zeta", gamesCount: 2 }, { name: "alpha", gamesCount: 1 }, { name: "Mu", gamesCount: 0 }]
        )
      end

      it "sorts by name ignoring case" do
        expect(list(sortBy: "NAME")[:nodes].pluck(:name)).to eq(["alpha", "Mu", "Zeta"])
      end

      it "sorts by most recently added" do
        expect(list(sortBy: "RECENTLY_ADDED")[:nodes].pluck(:name)).to eq(["alpha", "Mu", "Zeta"])
      end

      it "filters by name, ignoring case, and counts only the matches" do
        result = list(nameContains: "ZE")

        expect(result[:totalCount]).to eq(1)
        expect(result[:nodes].pluck(:name)).to eq(["Zeta"])
      end
    end
  end

  describe "companies gamesCount" do
    let(:query_string) do
      <<-GRAPHQL
        query {
          companies(sortBy: MOST_GAMES) {
            nodes {
              name
              gamesCount
            }
          }
        }
      GRAPHQL
    end

    it "counts developed and published games, each game once" do
      company = create(:company, name: "Valve")
      both = create(:game)
      create(:game_developer, company: company, game: both)
      create(:game_publisher, company: company, game: both)
      create(:game_developer, company: company)
      create(:game_publisher, company: company)
      create(:game_publisher, company: create(:company, name: "Other"))

      expect(api_request(query_string, token: access_token).graphql_dig(:companies, :nodes)).to eq(
        [{ name: "Valve", gamesCount: 3 }, { name: "Other", gamesCount: 1 }]
      )
    end

    it "counts the same games for a single company" do
      company = create(:company)
      game = create(:game)
      create(:game_developer, company: company, game: game)
      create(:game_publisher, company: company, game: game)
      create(:game_publisher, company: company)

      result = api_request('query($id: ID!) { company(id: $id) { gamesCount } }', variables: { id: company.id }, token: access_token)

      expect(result.graphql_dig(:company, :gamesCount)).to eq(2)
    end
  end

  describe "coverGames" do
    let(:query_string) do
      <<-GRAPHQL
        query {
          genres(sortBy: NAME) {
            nodes {
              name
              coverGames {
                name
                coverUrl
              }
            }
          }
        }
      GRAPHQL
    end
    let(:genre) { create(:genre, name: "Action") }

    def cover_game_names
      api_request(query_string, token: access_token).graphql_dig(:genres, :nodes).to_h do |node|
        [node[:name], node[:coverGames].pluck(:name)]
      end
    end

    it "returns up to four games with covers, most-owned first" do
      games = Array.new(5) { |i| create(:game, :cover, name: "Game #{i}") }
      games.each { |game| create(:game_genre, game: game, genre: genre) }
      create(:game_genre, game: create(:game, name: "No cover"), genre: genre)
      create_list(:game_purchase, 2, game: games[3])
      create(:game_purchase, game: games[1])
      create(:genre, name: "Empty")

      expect(cover_game_names).to eq(
        "Action" => ["Game 3", "Game 1", "Game 0", "Game 2"],
        "Empty" => []
      )
    end

    it "runs no more queries as the list grows" do
      create(:game_genre, game: create(:game, :cover), genre: genre)
      # The first request generates the cover variants, which writes records
      # and is unrelated to batching, so warm those up and measure the second.
      api_request(query_string, token: access_token)
      baseline = query_count { api_request(query_string, token: access_token) }

      2.times { |i| create(:game_genre, game: create(:game, :cover), genre: create(:genre, name: "Genre #{i}")) }
      api_request(query_string, token: access_token)

      expect(query_count { api_request(query_string, token: access_token) }).to eq(baseline)
    end
  end

  describe "coverGames on companies and engines" do
    def covers(field)
      query = "query { #{field}(sortBy: NAME) { nodes { name coverGames { name } } } }"
      api_request(query, token: access_token).graphql_dig(field, :nodes).to_h do |node|
        [node[:name], node[:coverGames].pluck(:name)]
      end
    end

    it "uses games a company developed or published, each once" do
      company = create(:company, name: "Valve")
      both = create(:game, :cover, name: "Both")
      create(:game_developer, company: company, game: both)
      create(:game_publisher, company: company, game: both)
      create(:game_purchase, game: both)
      create(:game_publisher, company: company, game: create(:game, :cover, name: "Published"))

      expect(covers(:companies)).to eq("Valve" => ["Both", "Published"])
    end

    it "uses games built with an engine" do
      engine = create(:engine, name: "Source")
      create(:game_engine, engine: engine, game: create(:game, :cover, name: "Half-Life 2"))
      create(:game_engine, engine: engine, game: create(:game, name: "No cover"))

      expect(covers(:engines)).to eq("Source" => ["Half-Life 2"])
    end
  end
end
