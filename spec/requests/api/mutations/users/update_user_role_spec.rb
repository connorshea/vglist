# typed: false
require 'rails_helper'

RSpec.describe "UpdateUserRole Mutation API", type: :request do
  describe "Mutation updates the user's role" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!, $role: UserRole!) {
          updateUserRole(userId: $id, role: $role) {
            user {
              id
              username
              role
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let!(:user) { create(:confirmed_admin) } # rubocop:disable RSpec/LetSetup
      let(:user2) { create(:confirmed_user) }
      let(:user3) { create(:confirmed_admin) }

      it "decreases the number of users with member role" do
        user2

        expect do
          api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)
        end.to change(User.where(role: :member), :count).by(-1)
      end

      it "increases the number of users with moderator role" do
        user2

        expect do
          api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)
        end.to change(User.where(role: :moderator), :count).by(1)
      end

      it "increases the number of users with admin role" do
        user2

        expect do
          api_request(query_string, variables: { id: user2.id, role: 'ADMIN' }, token: access_token)
        end.to change(User.where(role: :admin), :count).by(1)
      end

      it "decreases the number of users with admin role" do
        user3

        expect do
          api_request(query_string, variables: { id: user3.id, role: 'MEMBER' }, token: access_token)
        end.to change(User.where(role: :admin), :count).by(-1)
      end

      it "returns basic data for user after making them a moderator" do
        user2

        result = api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)

        expect(result.graphql_dig(:update_user_role, :user)).to eq(
          {
            id: user2.id.to_s,
            username: user2.username,
            role: 'MODERATOR'
          }
        )
      end

      it "does not change if the user already has the role" do
        user2.update!(role: :moderator)

        expect do
          result = api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("User already has the moderator role.")
        end.not_to change(User.where(role: :moderator), :count)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }
      let(:user2) { create(:confirmed_user) }

      it "does not change the number of moderators" do
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update the role of this user.")
        end.not_to change(User.where(role: :moderator), :count)
      end
    end

    context 'when the current user is a moderator' do
      let(:user) { create(:confirmed_moderator) }
      let(:user2) { create(:confirmed_user) }

      it "does not change the number of moderators" do
        user
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id, role: 'MODERATOR' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update the role of this user.")
        end.not_to change(User.where(role: :moderator), :count)
      end
    end
  end
end
