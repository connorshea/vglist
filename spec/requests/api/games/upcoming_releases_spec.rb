# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Upcoming releases API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }

  let!(:bare) { create(:game, release_date: 1.week.from_now) }
  let!(:covered) { create(:game, :cover, :wikidata_id, release_date: 2.weeks.from_now) }

  let(:query_string) do
    <<~GRAPHQL
      query($first: Int) {
        upcomingReleases(first: $first) {
          id
          isInLibrary
        }
      }
    GRAPHQL
  end

  it "lists games with covers first, with the current user's library status" do
    create(:game_purchase, user: user, game: bare)

    result = api_request(query_string, token: access_token)
    games = result.graphql_dig(:upcoming_releases)

    expect(games.pluck(:id)).to eq([covered.id.to_s, bare.id.to_s])
    expect(games.pluck(:isInLibrary)).to eq([false, true])
  end

  it "returns only as many games as asked for" do
    result = api_request(query_string, variables: { first: 1 }, token: access_token)

    expect(result.graphql_dig(:upcoming_releases).pluck(:id)).to eq([covered.id.to_s])
  end

  it "rejects asking for more than the maximum" do
    result = api_request(query_string, variables: { first: UpcomingReleases::MAX + 1 }, token: access_token)

    expect(api_result_errors(result)).to be_present
  end
end
