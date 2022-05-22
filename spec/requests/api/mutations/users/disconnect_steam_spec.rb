# typed: false
require 'rails_helper'

RSpec.describe "DisconnectSteam Mutation API", type: :request do
  describe "Mutation deletes the ExternalAccount" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          disconnectSteam(userId: $id) {
            disconnected
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:external_account) { create(:external_account) }
      let!(:user) { create(:confirmed_admin, external_account: external_account) }
      let(:external_account2) { create(:external_account) }
      let!(:user2) { create(:confirmed_user, external_account: external_account2) }

      it "does not disconnect the other user's Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to disconnect this user's Steam account.")
        end.not_to change(ExternalAccount, :count)
      end

      it "can disconnect their own account" do
        expect do
          result = api_request(query_string, variables: { id: user.id }, token: access_token)
          expect(result.graphql_dig(:disconnect_steam)).to eq(
            {
              disconnected: true
            }
          )
        end.to change(ExternalAccount, :count).by(-1)
      end
    end

    context 'when the current user is a normal member' do
      let(:external_account) { create(:external_account) }
      let!(:user) { create(:confirmed_user, external_account: external_account) }
      let(:external_account2) { create(:external_account) }
      let!(:user2) { create(:confirmed_user, external_account: external_account2) }

      it "does not disconnect the other user's Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to disconnect this user's Steam account.")
        end.not_to change(ExternalAccount, :count)
      end

      it "they are able to disconnect their own Steam account" do
        expect do
          result = api_request(query_string, variables: { id: user.id }, token: access_token)
          expect(result.graphql_dig(:disconnect_steam)).to eq(
            {
              disconnected: true
            }
          )
        end.to change(ExternalAccount, :count).by(-1)
      end
    end
  end
end
