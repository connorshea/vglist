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

  describe "PUT release_path" do
    let(:user) { create(:confirmed_user) }
    let!(:release) { create(:release) }
    let(:release_attributes) { attributes_for(:release) }

    it "updates release description" do
      sign_in(user)
      release_attributes[:description] = "Description goes here"
      put release_path(id: release.id), params: { release: release_attributes }
      expect(release.reload.description).to eql("Description goes here")
    end
  end

  describe "DELETE release_path" do
    let(:user) { create(:confirmed_user) }
    let!(:release) { create(:release) }

    it "deletes a release" do
      sign_in(user)
      expect {
        delete release_path(id: release.id)
      }.to change(Release, :count).by(-1)
    end
  end
end
