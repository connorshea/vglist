# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Remove from Unmatched Games Mutation API", type: :request do
  describe "Mutation removes the Unmatched Game entries" do
    let(:access_token) { JwtService.encode(user) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeFromUnmatchedGames(externalServiceName: STEAM, externalServiceId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:unmatched_game) { create(:unmatched_game, external_service_id: '100') }
      let(:unmatched_games) { create_list(:unmatched_game, 5, external_service_name: 'Steam', external_service_id: '123') }

      it "decreases the number of Unmatched Game entries" do
        unmatched_game

        expect do
          api_request(query_string, variables: { id: unmatched_game.external_service_id }, token: access_token)
        end.to change(UnmatchedGame, :count).by(-1)
      end

      it "decreases the number of Unmatched Game entries when deleting multiple" do
        unmatched_games

        expect do
          api_request(query_string, variables: { id: '123' }, token: access_token)
        end.to change(UnmatchedGame, :count).by(-5)
      end

      it "returns deleted true" do
        result = api_request(query_string, variables: { id: unmatched_game.external_service_id }, token: access_token)

        expect(result.graphql_dig(:remove_from_unmatched_games, :deleted)).to eq(true)
      end
    end

    [:moderator, :user].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }
        let!(:unmatched_game) { create(:unmatched_game, external_service_id: '100') }

        it "does not remove the Unmatched Game entries" do
          expect do
            result = api_request(query_string, variables: { id: unmatched_game.external_service_id }, token: access_token)
            expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove Unmatched Game entries.")
          end.not_to change(UnmatchedGame, :count)
        end
      end
    end

    context 'when there is no current user' do
      let!(:unmatched_game) { create(:unmatched_game, external_service_id: '100') }

      it "does not remove the Unmatched Game entries" do
        expect do
          result = api_request(query_string, variables: { id: unmatched_game.external_service_id }, token: nil)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove Unmatched Game entries.")
        end.not_to change(UnmatchedGame, :count)
      end
    end
  end
end
