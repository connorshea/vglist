require 'rails_helper'

RSpec.describe "Releases", type: :request do
  describe "GET releases_path" do
    it "returns http success" do
      get releases_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET release_path" do
    let(:release) { create(:release) }
    
    it "returns http success" do
      get release_path(id: release.id)
      expect(response).to have_http_status(:success)
    end
  end
end
