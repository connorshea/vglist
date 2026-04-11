require 'rails_helper'

RSpec.describe "SPA", type: :request do
  describe "GET /*path (SPA fallback)" do
    # In test env, SpaController falls back to 'http://localhost:5173' when
    # FRONTEND_URL isn't set. These tests rely on that default.
    let(:frontend) { 'http://localhost:5173' }

    it "redirects the root path to the frontend" do
      get '/'
      expect(response).to redirect_to("#{frontend}/")
    end

    it "redirects unknown paths to the same path on the frontend" do
      get '/games'
      expect(response).to redirect_to("#{frontend}/games")
    end

    it "redirects nested paths to the frontend" do
      get '/users/1/favorites'
      expect(response).to redirect_to("#{frontend}/users/1/favorites")
    end

    it "preserves the query string in the redirect" do
      get '/games?page=2&sort=name'
      expect(response).to redirect_to("#{frontend}/games?page=2&sort=name")
    end

    it "uses a 302 redirect (not permanent) during the domain transition" do
      get '/'
      expect(response).to have_http_status(:found)
    end

    it "does not intercept the GraphQL endpoint" do
      post '/graphql', params: { query: '{ __typename }' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('data')
    end

    it "does not intercept API auth endpoints" do
      post '/api/auth/sign_in', params: { email: "x", password: "y" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
