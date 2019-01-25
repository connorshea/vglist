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

  describe "POST platforms_path" do
    let(:user) { create(:confirmed_moderator) }
    let(:attributes) { attributes_for(:platform) }

    it "creates a new platform" do
      sign_in(user)
      expect {
        post platforms_path, params: { platform: attributes }
      }.to change{ Platform.count }.by(1)
    end
  end

  describe "PUT platform_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:platform) { create(:platform) }
    let(:platform_attributes) { attributes_for(:platform) }

    it "updates platform description" do
      sign_in(user)
      platform_attributes[:description] = "Description goes here"
      put platform_path(id: platform.id), params: { platform: platform_attributes }
      expect(platform.reload.description).to eql("Description goes here")
    end
  end

  describe "DELETE platform_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:platform) { create(:platform) }

    it "deletes a platform" do
      sign_in(user)
      expect {
        delete platform_path(id: platform.id)
      }.to change{ Platform.count }.by(-1)
    end
  end

  describe "GET search_platforms_path" do
    let(:user) { create(:confirmed_user) }
    let(:platform) { create(:platform) }

    it "returns the given platform" do
      sign_in(user)
      get search_platforms_path(query: platform.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(platform.to_json)
    end

    it "returns no platform" do
      sign_in(user)
      get search_platforms_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no platform when no query is given" do
      sign_in(user)
      get search_platforms_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
