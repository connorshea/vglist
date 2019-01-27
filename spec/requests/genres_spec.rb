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

  describe "POST genres_path" do
    let(:user) { create(:confirmed_moderator) }
    let(:genre_attributes) { attributes_for(:genre) }

    it "creates a new genre" do
      sign_in(user)
      expect {
        post genres_path, params: { genre: genre_attributes }
      }.to change(Genre, :count).by(1)
    end

    it "fails to create a new genre" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      genre_attributes[:name] = long_name
      post genres_path, params: { genre: genre_attributes }
      expect(response.body).to include('Unable to save genre.')
    end
  end

  describe "PUT genre_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:genre) { create(:genre) }
    let(:genre_attributes) { attributes_for(:genre) }

    it "updates genre description" do
      sign_in(user)
      genre_attributes[:description] = "Description goes here"
      put genre_path(id: genre.id), params: { genre: genre_attributes }
      expect(genre.reload.description).to eql("Description goes here")
    end

    it "fails to update genre" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      genre_attributes[:name] = long_name
      put genre_path(id: genre.id), params: { genre: genre_attributes }
      expect(response.body).to include('Unable to update genre.')
    end
  end

  describe "DELETE genre_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:genre) { create(:genre) }

    it "deletes a genre" do
      sign_in(user)
      expect {
        delete genre_path(id: genre.id)
      }.to change(Genre, :count).by(-1)
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
