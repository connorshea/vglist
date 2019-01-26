require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET users_path" do
    it "returns http success" do
      get users_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET user_path" do
    let(:user) { create(:user) }

    it "returns http success" do
      get user_path(id: user.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST update_role_user_path" do
    let(:admin) { create(:confirmed_admin) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }
    let(:another_user) { create(:confirmed_user) }

    it "makes the user a moderator" do
      sign_in(admin)
      post update_role_user_path(id: user.id, role: "moderator")
      expect(user.reload.role).to eql('moderator')
    end

    it "makes the user an admin" do
      sign_in(admin)
      post update_role_user_path(id: user.id, role: "admin")
      expect(user.reload.role).to eql('admin')
    end

    it "moderator cannot make another user a moderator" do
      sign_in(moderator)
      expect {
        post update_role_user_path(id: user.id, role: "moderator")
      }.to raise_error(Pundit::NotAuthorizedError)
      expect(user.reload.role).to eql('member')
      expect(user.reload.role).not_to eql('moderator')
    end

    it "user cannot make another user a moderator" do
      sign_in(another_user)
      expect {
        post update_role_user_path(id: user.id, role: "moderator")
      }.to raise_error(Pundit::NotAuthorizedError)
      expect(user.reload.role).to eql('member')
      expect(user.reload.role).not_to eql('moderator')
    end
  end
end
