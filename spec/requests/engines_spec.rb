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
    let(:engine_with_everything) { create(:engine_with_everything) }

    it "returns http success" do
      get engine_path(id: engine.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for engine that has everything" do
      get engine_path(id: engine_with_everything.id)
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

  describe "POST engines_path" do
    let(:user) { create(:confirmed_user) }
    let(:engine_attributes) { attributes_for(:engine) }

    it "creates a new engine" do
      sign_in(user)
      expect do
        post engines_path, params: { engine: engine_attributes }
      end.to change(Engine, :count).by(1)
    end

    it "fails to create a new engine" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      engine_attributes[:name] = long_name
      post engines_path, params: { engine: engine_attributes }
      expect(response.body).to include('Unable to create engine.')
    end
  end

  describe "PUT engine_path" do
    let(:user) { create(:confirmed_user) }
    let!(:engine) { create(:engine) }
    let(:engine_attributes) { attributes_for(:engine) }

    it "updates engine name" do
      sign_in(user)
      engine_attributes[:name] = "Name goes here"
      put engine_path(id: engine.id), params: { engine: engine_attributes }
      expect(engine.reload.name).to eql("Name goes here")
    end

    it "fails to update engine" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      engine_attributes[:name] = long_name
      put engine_path(id: engine.id), params: { engine: engine_attributes }
      expect(response.body).to include('Unable to update engine.')
    end
  end

  describe "DELETE engine_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:engine) { create(:engine) }

    it "deletes an engine" do
      sign_in(user)
      expect do
        delete engine_path(id: engine.id)
      end.to change(Engine, :count).by(-1)
    end
  end

  describe "GET search_engines_path" do
    let(:user) { create(:confirmed_user) }
    let(:engine) { create(:engine) }

    it "returns the given engine" do
      sign_in(user)
      get search_engines_path(query: engine.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(engine.to_json)
    end

    it "returns no engine" do
      sign_in(user)
      get search_engines_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no engine when no query is given" do
      sign_in(user)
      get search_engines_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
