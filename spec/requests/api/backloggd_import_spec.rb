# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "User backloggdImport field", type: :request do
  let(:query_string) do
    <<-GRAPHQL
      query($id: ID!) {
        user(id: $id) {
          backloggdImport {
            username
            status
            errorMessage
            addedGames { id }
            unmatchedGames { name slug url }
          }
        }
      }
    GRAPHQL
  end
  let(:user) { create(:confirmed_user) }
  let(:game) { create(:game) }

  before(:each) do
    BackloggdImport.create!(
      user: user,
      username: 'Example',
      status: :succeeded,
      added_game_ids: [game.id],
      unmatched_games: [{ name: 'Some Obscure Game', slug: 'some-obscure-game' }]
    )
  end

  it 'shows the user their import' do
    result = api_request(query_string, variables: { id: user.id }, token: JwtService.encode(user))

    expect(result.graphql_dig(:user, :backloggd_import)).to eq(
      {
        username: 'Example',
        status: 'SUCCEEDED',
        errorMessage: nil,
        addedGames: [{ id: game.id.to_s }],
        unmatchedGames: [{ name: 'Some Obscure Game', slug: 'some-obscure-game', url: 'https://backloggd.com/games/some-obscure-game/' }]
      }
    )
  end

  it 'reports an abandoned import as failed' do
    user.backloggd_import.update!(status: :running, updated_at: 1.hour.ago)

    result = api_request(query_string, variables: { id: user.id }, token: JwtService.encode(user))

    expect(result.graphql_dig(:user, :backloggd_import)).to include(status: 'FAILED', errorMessage: 'The import stopped partway. Try again.')
  end

  it 'hides it from everyone else' do
    result = api_request(query_string, variables: { id: user.id }, token: JwtService.encode(create(:confirmed_user)))

    expect(result.graphql_dig(:user, :backloggd_import)).to be_nil
  end
end
