require 'rails_helper'

RSpec.describe "SPA", type: :request do
  describe "GET /*path (SPA fallback)" do
    let(:index_path) { Rails.root.join("public/index.html") }
    let(:index_content) { '<!DOCTYPE html><html><body><div id="app"></div></body></html>' }

    context "when public/index.html exists" do
      before(:each) { File.write(index_path, index_content) }
      after(:each) { File.delete(index_path) if File.exist?(index_path) }

      it "serves the SPA for the root path" do
        get '/'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/html')
      end

      it "serves the SPA for frontend routes" do
        get '/games'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/html')
      end

      it "serves the SPA for nested frontend routes" do
        get '/users/1/favorites'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/html')
      end

      it "sets the Content-Security-Policy header", :aggregate_failures do
        get '/games'
        csp = response.headers['Content-Security-Policy']
        expect(csp).to be_present
        expect(csp).to include("default-src 'self' https:")
        expect(csp).to include("object-src 'none'")
        expect(csp).to include("frame-ancestors 'none'")
        expect(csp).to include("script-src 'self' https:")
        expect(csp).to include("style-src 'self' https: 'unsafe-inline'")
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

    context "when public/index.html does not exist" do
      before(:each) { File.delete(index_path) if File.exist?(index_path) }

      it "returns a 404 JSON error" do
        get '/'
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Frontend not built')
      end
    end
  end
end
