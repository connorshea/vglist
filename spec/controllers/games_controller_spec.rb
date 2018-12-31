require 'rails_helper'

RSpec.describe GamesController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns http success" do
      @game1 = create(:game)
      get :show, params: { id: @game1.id }
      expect(response).to have_http_status(:success)
    end
  end

end
