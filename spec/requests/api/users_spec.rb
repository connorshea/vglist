# typed: false
require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "Query for data on users" do
    let(:user) { create(:confirmed_user) }

    it "returns basic data for user" do
      sign_in(user)
      user
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            role
            privacy
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
          "privacy" => user.privacy.upcase
        }
      )
    end
  end
end
