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
end
