# typed: false
require 'rails_helper'

RSpec.describe "RemoveUserAvatar Mutation API", type: :request do
  describe "Mutation removes the user's avatar" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeUserAvatar(userId: $id) {
            user {
              id
              username
              avatarUrl(size: SMALL)
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let!(:user) { create(:confirmed_admin) } # rubocop:disable RSpec/LetSetup
      let(:user2) { create(:user_with_avatar) }

      it "increases the number of users without avatars" do
        user2

        expect do
          api_request(query_string, variables: { id: user2.id }, token: access_token)
        end.to change(User.where.missing(:avatar_attachment), :count).by(1)
      end

      it "returns basic data for user after removing avatar" do
        user2

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)

        expect(result.graphql_dig(:remove_user_avatar, :user)).to eq(
          {
            id: user2.id.to_s,
            username: user2.username,
            avatarUrl: nil
          }
        )
      end
    end

    context 'when the current user is a normal member' do
      let!(:user) { create(:confirmed_user) } # rubocop:disable RSpec/LetSetup
      let(:user2) { create(:user_with_avatar) }

      it "does not change the number of users with avatars" do
        user2

        expect do
          result = api_request(query_string, variables: { id: user2.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove this user's avatar.")
        end.not_to change(User.where.missing(:avatar_attachment), :count)
      end
    end

    context 'when the current user is a normal member removing their own avatar' do
      let(:user) { create(:user_with_avatar) }

      it "increases the number of users without avatars" do
        user

        expect do
          api_request(query_string, variables: { id: user.id }, token: access_token)
        end.to change(User.where.missing(:avatar_attachment), :count).by(1)
      end
    end
  end
end
