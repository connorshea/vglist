# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Recent library additions API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }

  let!(:older) { create(:game) }
  let!(:newer) { create(:game) }

  let(:query_string) do
    <<~GRAPHQL
      query($first: Int) {
        recentLibraryAdditions(first: $first) {
          id
          isInLibrary
        }
      }
    GRAPHQL
  end

  before(:each) do
    create(:game_purchase, user: user, game: older, created_at: 2.hours.ago)
    create(:game_purchase, game: newer, created_at: 1.hour.ago)
  end

  it "lists the most recently added games first, with the current user's library status" do
    result = api_request(query_string, token: access_token)
    games = result.graphql_dig(:recent_library_additions)

    expect(games.pluck(:id)).to eq([newer.id.to_s, older.id.to_s])
    expect(games.pluck(:isInLibrary)).to eq([false, true])
  end

  it "returns only as many games as asked for" do
    result = api_request(query_string, variables: { first: 1 }, token: access_token)

    expect(result.graphql_dig(:recent_library_additions).pluck(:id)).to eq([newer.id.to_s])
  end

  it "rejects asking for more than the maximum" do
    result = api_request(query_string, variables: { first: RecentLibraryAdditions::MAX + 1 }, token: access_token)

    expect(api_result_errors(result)).to be_present
  end
end
