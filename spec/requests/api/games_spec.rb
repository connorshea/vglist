# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it "returns basic data for game" do
      sign_in(user)
      game
      query_string = <<-GRAPHQL
        query($id: ID!){
          game(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )
      expect(result.to_h["data"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end
  end
end
