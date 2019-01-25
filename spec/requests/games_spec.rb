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

    it "creates a new game" do
      sign_in(user)
      expect {
        post games_path, params: { game: attributes }
      }.to change{ Game.count }.by(1)
    end
  end

  describe "PUT game_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game) { create(:game) }
    let(:game_attributes) { attributes_for(:game) }

    it "updates game description" do
      sign_in(user)
      game_attributes[:description] = "Description goes here"
      put game_path(id: game.id), params: { game: game_attributes }
      expect(game.reload.description).to eql("Description goes here")
    end
  end

  describe "DELETE game_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game) { create(:game) }

    it "deletes a game" do
      sign_in(user)
      expect {
        delete game_path(id: game.id)
      }.to change{ Game.count }.by(-1)
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
