# typed: false
require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "Query for data on users" do
    let(:user) { create(:confirmed_user) }
    let(:user_with_avatar) { create(:confirmed_user_with_avatar) }

    it "returns basic data for user" do
      sign_in(user)
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: user.id }
      )
      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user.id.to_s,
          "username" => user.username,
          "role" => user.role.upcase,
          "privacy" => user.privacy.upcase,
          "avatarUrl" => nil
        }
      )
    end

    it "returns avatar for user" do
      sign_in(user_with_avatar)
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            avatarUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user_with_avatar },
        variables: { id: user_with_avatar.id }
      )
      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user_with_avatar.id.to_s,
          "username" => user_with_avatar.username,
          "avatarUrl" => Rails.application.routes.url_helpers.rails_blob_url(user_with_avatar.avatar_attachment, only_path: true)
        }
      )
    end
  end
end
