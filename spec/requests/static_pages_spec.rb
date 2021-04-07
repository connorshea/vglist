# typed: false
require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET about_path" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET graphiql_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      get graphiql_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success when signed in" do
      sign_in(user)

      get graphiql_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET opensearch_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      get opensearch_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success when signed in" do
      sign_in(user)

      get opensearch_path
      expect(response).to have_http_status(:success)
    end
  end
end
