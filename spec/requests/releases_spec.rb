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

    it "does not update release description" do
      sign_in(user)
      long_description = Faker::Lorem.characters(1200)
      release_attributes[:description] = long_description
      put release_path(id: release.id), params: { release: release_attributes }
      expect(release.reload.description).not_to eql(long_description)
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

  describe "POST add_release_to_library_release_path" do
    let(:user) { create(:confirmed_user) }
    let(:release) { create(:release) }
    let(:user_with_release) { create(:confirmed_user) }
    let(:release_purchase) { create(:release_purchase, user: user_with_release, release: release) }

    it "adds a release to the user's library" do
      sign_in(user)
      expect {
        post add_release_to_library_release_path(release.id),
          params: { release_purchase: { user_id: user.id, release_id: release.id } }
      }.to change(user.release_purchases.all, :count).by(1)
    end

    it "removes a release from the user's library" do
      sign_in(user_with_release)
      # Load the release purchase.
      release_purchase
      expect {
        delete remove_release_from_library_release_path(release.id),
          params: { id: release.id }
      }.to change(user_with_release.release_purchases.all, :count).by(-1)
    end

    it "doesn't remove a release from the user's library if none exist" do
      sign_in(user)
      delete remove_release_from_library_release_path(release.id),
        params: { id: release.id }
      expect(response).to redirect_to(release_url(release))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Unable to remove release from your library.")
    end
  end
end
