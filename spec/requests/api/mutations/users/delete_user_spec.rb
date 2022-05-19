# typed: false
require 'rails_helper'

RSpec.describe "DeleteUser Mutation API", type: :request do
  describe "Mutation deletes the user" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          deleteUser(userId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:user2) { create(:confirmed_user) }

      it "does not delete the user" do
        user
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this user.")
        end.not_to change(User, :count)
      end

      it "they are able to delete themselves" do
        user

        expect do
          result = api_request(query_string, variables: { id: user.id }, token: access_token)
        end.to change(User, :count).by(-1)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }
      let(:user2) { create(:confirmed_user) }

      it "does not delete the user" do
        user
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this user.")
        end.not_to change(User, :count)
      end

      it "they are able to delete themselves" do
        user

        expect do
          result = api_request(query_string, variables: { id: user.id }, token: access_token)
        end.to change(User, :count).by(-1)
      end
    end
  end
end
