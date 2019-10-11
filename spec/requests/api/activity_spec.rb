# typed: false
require 'rails_helper'

RSpec.describe "Activity API", type: :request do
  describe "Query for data on activity globally" do
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user) }

    it "returns basic data for activity events" do
      sign_in(user)
      game_purchase
      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            user {
              username
            }
            eventable {
              __typename
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )
      expect(result.to_h["data"]["activity"]).to eq(
        [
          {
            "user" => {
              "username" => user.username
            },
            "eventable" => {
              "__typename" => "GamePurchase"
            }
          },
          {
            "user" => {
              "username" => user.username
            },
            "eventable" => {
              "__typename" => "User"
            }
          }
        ]
      )
    end
  end
end
