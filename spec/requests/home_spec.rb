require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET root_path" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET root_path as normal user" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET root_path as an admin" do
    let(:admin) { create(:confirmed_admin) }

    it "returns http success" do
      sign_in(admin)
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET root_path games display" do
    it "only shows games with covers" do
      # Create a game with a cover
      game_with_cover = create(:game_with_cover, name: "Game With Cover")
      # Create a game without a cover
      game_without_cover = create(:game, name: "Game Without Cover")

      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(game_with_cover.name)
      expect(response.body).not_to include(game_without_cover.name)
    end
  end
end
