require 'rails_helper'

RSpec.describe "Engines", type: :request do
  describe "GET engines_path" do
    it "returns http success" do
      get engines_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET engine_path" do
    let(:engine) { create(:engine) }

    it "returns http success" do
      get engine_path(id: engine.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_engine_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)

      get new_engine_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_engine_path" do
    let(:user) { create(:confirmed_user) }
    let(:engine) { create(:engine) }

    it "returns http success" do
      sign_in(user)

      get edit_engine_path(engine.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE engine_path" do
    let(:user) { create(:confirmed_user) }
    let!(:engine) { create(:engine) }

    it "deletes an engine" do
      sign_in(user)
      expect {
        delete engine_path(id: engine.id)
      }.to change(Engine, :count).by(-1)
    end
  end
end
