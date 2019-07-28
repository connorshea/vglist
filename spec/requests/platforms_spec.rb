# typed: false
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
    let(:platform_with_everything) { create(:platform_with_everything) }

    it "returns http success" do
      get platform_path(id: platform.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for platform that has everything" do
      get platform_path(id: platform_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_platform_path" do
    let(:user) { create(:confirmed_admin) }

    it "returns http success" do
      sign_in(user)
      get new_platform_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_platform_path" do
    let(:user) { create(:confirmed_admin) }
    let(:platform) { create(:platform) }
    let(:platform_with_everything) { create(:platform_with_everything) }

    it "returns http success" do
      sign_in(user)
      get edit_platform_path(id: platform.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for platform that has everything" do
      sign_in(user)
      get edit_platform_path(id: platform_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST platforms_path" do
    let(:user) { create(:confirmed_moderator) }
    let(:attributes) { attributes_for(:platform) }

    it "creates a new platform" do
      sign_in(user)
      expect do
        post platforms_path, params: { platform: attributes }
      end.to change(Platform, :count).by(1)
    end

    it "fails to create a new platform" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      attributes[:name] = long_name
      post platforms_path, params: { platform: attributes }
      expect(response.body).to include('Unable to save platform.')
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

    it "fails to update platform" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      platform_attributes[:name] = long_name
      put platform_path(id: platform.id), params: { platform: platform_attributes }
      expect(response.body).to include('Unable to update platform.')
    end
  end

  describe "DELETE platform_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:platform) { create(:platform) }

    it "deletes a platform" do
      sign_in(user)
      expect do
        delete platform_path(id: platform.id)
      end.to change(Platform, :count).by(-1)
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
