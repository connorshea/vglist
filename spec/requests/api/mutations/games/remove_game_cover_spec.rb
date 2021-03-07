# typed: false
require 'rails_helper'

RSpec.describe "RemoveGameCover Mutation API", type: :request do
  describe "Mutation removes the game's cover" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeGameCover(gameId: $id) {
            game {
              id
              name
              coverUrl(size: SMALL)
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:game) { create(:game_with_cover) }

      it "increases the number of games without covers" do
        game

        expect do
          api_request(query_string, variables: { id: game.id }, token: access_token)
        end.to change(Game.where.missing(:cover_attachment), :count).by(1)
      end

      it "returns basic data for game after removing cover" do
        game

        result = api_request(query_string, variables: { id: game.id }, token: access_token)

        expect(result.graphql_dig(:remove_game_cover, :game)).to eq(
          {
            id: game.id.to_s,
            name: game.name,
            coverUrl: nil
          }
        )
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }
      let(:game) { create(:game_with_cover) }

      it "does not change the number of games with covers" do
        game

        expect do
          result = api_request(query_string, variables: { id: game.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove this game's cover.")
        end.not_to change(Game.where.missing(:cover_attachment), :count)
      end
    end
  end
end
