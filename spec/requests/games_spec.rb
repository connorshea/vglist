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
end
