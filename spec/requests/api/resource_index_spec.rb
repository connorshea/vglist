# frozen_string_literal: true

require 'rails_helper'

# The genre and platform index pages. `series_spec.rb` covers seriesList.
RSpec.describe "Genre and platform index API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }

  {
    genres: { model: :genre, join: :game_genre },
    platforms: { model: :platform, join: :game_platform }
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
end
