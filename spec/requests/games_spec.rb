require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe "GET games_path" do
    it "returns http success" do
      get games_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET game_path" do
    let(:game) { create(:game) }

    it "returns http success" do
      get game_path(id: game.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST games_path" do
    let(:user) { create(:confirmed_user) }
    let(:attributes) { attributes_for(:game) }

    it "returns http found" do
      sign_in(user)
      post games_path, params: { game: attributes }
      expect(response).to have_http_status(:found)
    end
  end

  describe "GET search_games_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it "returns the given game" do
      sign_in(user)
      get search_games_path(query: game.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(game.to_json)
    end

    it "returns no game" do
      sign_in(user)
      get search_games_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no game when no query is given" do
      sign_in(user)
      get search_games_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
