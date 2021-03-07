# typed: false
require 'rails_helper'

RSpec.describe "UnbanUser Mutation API", type: :request do
  describe "Mutation unbans the user" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          unbanUser(userId: $id) {
            user {
              id
              username
              banned
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:user2) { create(:confirmed_user, banned: true) }

      it "decreases the number of banned users" do
        user2

        expect do
          api_request(query_string, variables: { id: user2.id }, token: access_token)
        end.to change(User.where(banned: true), :count).by(-1)
      end

      it "returns basic data for user after unbanning them" do
        user2

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)

        expect(result.graphql_dig(:unban_user, :user)).to eq(
          {
            id: user2.id.to_s,
            username: user2.username,
            banned: false
          }
        )
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }
      let(:user2) { create(:confirmed_user) }

      it "does not change the number of banned users" do
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to unban this user.")
        end.not_to change(User.where(banned: true), :count)
      end
    end
  end
end
