require 'rails_helper'

RSpec.describe "Genres", type: :request do
  describe "GET genres_path" do
    it "returns http success" do
      get genres_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET genre_path" do
    let(:genre) { create(:genre) }

    it "returns http success" do
      get genre_path(id: genre.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET search_genres_path" do
    let(:user) { create(:confirmed_user) }
    let(:genre) { create(:genre) }

    it "returns the given genre" do
      sign_in(user)
      get search_genres_path(query: genre.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(genre.to_json)
    end

    it "returns no genre" do
      sign_in(user)
      get search_genres_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no genre when no query is given" do
      sign_in(user)
      get search_genres_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
