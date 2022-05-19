# typed: false
require 'rails_helper'

RSpec.describe "ResetUserLibrary Mutation API", type: :request do
  describe "Mutation deletes the user" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          resetUserLibrary(userId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:user_games) { create_list(:game_purchase, 10, user: user) }
      let(:user2) { create(:confirmed_user) }
      let(:user2_games) { create_list(:game_purchase, 10, user: user2) }

      it "does not reset the user's library" do
        user2_games

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to reset this user's library.")
        end.not_to change(GamePurchase, :count)
      end

      it "they are able to reset their own library" do
        user_games

        expect do
          api_request(query_string, variables: { id: user.id }, token: access_token)
        end.to change(GamePurchase, :count).by(-10)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }
      let(:user_games) { create_list(:game_purchase, 10, user: user) }
      let(:user2) { create(:confirmed_user) }
      let(:user2_games) { create_list(:game_purchase, 10, user: user2) }

      it "does not reset the user's library" do
        user
        user2_games

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to reset this user's library.")
        end.not_to change(GamePurchase, :count)
      end

      it "they are able to reset their own library" do
        user_games

        expect do
          api_request(query_string, variables: { id: user.id }, token: access_token)
        end.to change(GamePurchase, :count).by(-10)
      end
    end
  end
end
