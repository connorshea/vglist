require 'rails_helper'

RSpec.describe PlatformsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    let(:platform) { create(:platform) }

    it "returns http success" do
      get :show, params: { id: platform.id }
      expect(response).to have_http_status(:success)
    end
  end

end
