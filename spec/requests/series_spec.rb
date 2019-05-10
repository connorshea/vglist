require 'rails_helper'

RSpec.describe "Series", type: :request do
  describe "GET series_index_path" do
    it "returns http success" do
      get series_index_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET series_path" do
    let(:series) { create(:series) }
    let(:series_with_everything) { create(:series_with_everything) }

    it "returns http success" do
      get series_path(id: series.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for series that has everything" do
      get series_path(id: series_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_series_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get new_series_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_series_path" do
    let(:user) { create(:confirmed_user) }
    let(:series) { create(:series) }
    let(:series_with_everything) { create(:series_with_everything) }

    it "returns http success" do
      sign_in(user)
      get edit_series_path(id: series.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for series that has everything" do
      sign_in(user)
      get edit_series_path(id: series_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST series_index_path" do
    let(:user) { create(:confirmed_user) }
    let(:series_attributes) { attributes_for(:series) }

    it "creates a new series" do
      sign_in(user)
      expect do
        post series_index_path, params: { series: series_attributes }
      end.to change(Series, :count).by(1)
    end

    it "fails to create a new series" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      series_attributes[:name] = long_name
      post series_index_path, params: { series: series_attributes }
      expect(response.body).to include('Unable to create series.')
    end
  end

  describe "PUT series_path" do
    let(:user) { create(:confirmed_user) }
    let!(:series) { create(:series) }
    let(:series_attributes) { attributes_for(:series) }

    it "updates series name" do
      sign_in(user)
      series_attributes[:name] = "Name goes here"
      put series_path(id: series.id), params: { series: series_attributes }
      expect(series.reload.name).to eql("Name goes here")
    end

    it "fails to update series" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      series_attributes[:name] = long_name
      put series_path(id: series.id), params: { series: series_attributes }
      expect(response.body).to include('Unable to update series.')
    end
  end

  describe "DELETE series_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:series) { create(:series) }

    it "deletes a series" do
      sign_in(user)
      expect do
        delete series_path(id: series.id)
      end.to change(Series, :count).by(-1)
    end

    it "redirects after deleting a series" do
      sign_in(user)
      delete series_path(id: series.id)
      follow_redirect!
      expect(response.body).to include('Series was successfully deleted.')
    end
  end

  describe "GET search_series_index_path" do
    let(:user) { create(:confirmed_user) }
    let(:series) { create(:series) }

    it "returns the given series" do
      sign_in(user)
      get search_series_index_path(query: series.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(series.to_json)
    end

    it "returns no series" do
      sign_in(user)
      get search_series_index_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no series when no query is given" do
      sign_in(user)
      get search_series_index_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
