require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    let(:game) { create(:game) }

    it "returns http success" do
      get :show, params: { id: game.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "returns http found" do
      post :create, params: {
        name: "Game",
        description: "Lorem ipsum"
      }
      expect(response).to have_http_status(:found)
    end
  end

  describe "POST #update" do
    let(:game) { create(:game) }

    it "returns http found" do
      post :update, params: {
        id: game.id,
        name: "Game",
        description: "Lorem ipsum"
      }
      expect(response).to have_http_status(:found)
    end
  end
end
