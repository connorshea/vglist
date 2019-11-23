# typed: false
require 'rails_helper'

RSpec.describe "Stores", type: :request do
  describe "GET stores_path" do
    it "returns http success" do
      get stores_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET store_path" do
    let(:store) { create(:store) }

    it "returns http success" do
      get store_path(id: store.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_store_path" do
    let(:user) { create(:confirmed_admin) }

    it "returns http success" do
      sign_in(user)
      get new_store_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_store_path" do
    let(:user) { create(:confirmed_admin) }
    let(:store) { create(:store) }

    it "returns http success" do
      sign_in(user)
      get edit_store_path(id: store.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST stores_path" do
    let(:user) { create(:confirmed_moderator) }
    let(:attributes) { attributes_for(:store) }

    it "creates a new store" do
      sign_in(user)
      expect do
        post stores_path, params: { store: attributes }
      end.to change(Store, :count).by(1)
    end

    it "fails to create a new store" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      attributes[:name] = long_name
      post stores_path, params: { store: attributes }
      expect(response.body).to include('Unable to create store.')
    end
  end

  describe "PUT store_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:store) { create(:store) }
    let(:store_attributes) { attributes_for(:store) }

    it "updates store name" do
      sign_in(user)
      store_attributes[:name] = "foobar"
      put store_path(id: store.id), params: { store: store_attributes }
      expect(store.reload.name).to eq("foobar")
    end

    it "fails to update store" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      store_attributes[:name] = long_name
      put store_path(id: store.id), params: { store: store_attributes }
      expect(response.body).to include('Unable to update store.')
    end
  end

  describe "DELETE store_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:store) { create(:store) }

    it "deletes a store" do
      sign_in(user)
      expect do
        delete store_path(id: store.id)
      end.to change(Store, :count).by(-1)
    end
  end

  describe "GET search_stores_path" do
    let(:user) { create(:confirmed_user) }
    let(:store) { create(:store) }

    it "returns the given store" do
      sign_in(user)
      get search_stores_path(query: store.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(store.to_json)
    end

    it "returns no store" do
      sign_in(user)
      get search_stores_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no store when no query is given" do
      sign_in(user)
      get search_stores_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
