require 'rails_helper'

RSpec.describe "Platforms", type: :request do
  describe "GET platforms_path" do
    it "returns http success" do
      get platforms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET platform_path" do
    let(:platform) { create(:platform) }

    it "returns http success" do
      get platform_path(id: platform.id)
      expect(response).to have_http_status(:success)
    end
  end
end
