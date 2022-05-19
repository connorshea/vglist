# typed: false
require 'rails_helper'

RSpec.describe "ImportSteamLibrary Mutation API", type: :request do
  describe "Mutation deletes the user" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          importSteamLibrary(userId: $id) {
            user {
              id
            }
            addedGames {
              id
            }
            updatedGames {
              id
            }
            addedGamesCount
            unmatchedCount
            updatedGamesCount
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:external_account) { create(:external_account) }
      let(:user) { create(:confirmed_admin, external_account: external_account) }
      let(:external_account2) { create(:external_account) }
      let(:user2) { create(:confirmed_user, external_account: external_account2) }
      let(:unmatched) { [SteamImportService::Unmatched.new(name: 'Foo', steam_id: rand(1..100_000))] }

      before(:each) do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(SteamImportService).to receive(:call).and_return(
          SteamImportService::Result.new(
            created: GamePurchase.none,
            updated: GamePurchase.none,
            unmatched: unmatched
          )
        )
        # rubocop:enable RSpec/AnyInstance
      end

      it "does not import the user's library" do
        user2

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)
        expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to import games for this user.")
      end

      it "they are able to import their own library" do
        result = api_request(query_string, variables: { id: user.id }, token: access_token)
        expect(result.graphql_dig(:import_steam_library, :user)).to eq(
          {
            id: user.id.to_s
          }
        )
      end
    end

    context 'when the current user is a normal member' do
      let(:external_account) { create(:external_account) }
      let(:user) { create(:confirmed_user, external_account: external_account) }
      let(:external_account2) { create(:external_account) }
      let(:user2) { create(:confirmed_user, external_account: external_account2) }
      let(:unmatched) { [SteamImportService::Unmatched.new(name: 'Foo', steam_id: rand(1..100_000))] }

      before(:each) do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(SteamImportService).to receive(:call).and_return(
          SteamImportService::Result.new(
            created: GamePurchase.none,
            updated: GamePurchase.none,
            unmatched: unmatched
          )
        )
        # rubocop:enable RSpec/AnyInstance
      end

      it "does not import the user's library" do
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to import games for this user.")
        end.not_to change(GamePurchase, :count)
      end

      it "they are able to import their own library" do
        user

        result = api_request(query_string, variables: { id: user.id }, token: access_token)
        expect(result.graphql_dig(:import_steam_library, :user)).to eq(
          {
            id: user.id.to_s
          }
        )
      end
    end
  end
end
