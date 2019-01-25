require 'rails_helper'

RSpec.describe "Companies", type: :request do
  describe "GET companies_path" do
    it "returns http success" do
      get companies_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET company_path" do
    let(:company) { create(:company) }

    it "returns http success" do
      get company_path(id: company.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET search_companies_path" do
    let(:user) { create(:confirmed_user) }
    let(:company) { create(:company) }

    it "returns the given company" do
      sign_in(user)
      get search_companies_path(query: company.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(company.to_json)
    end

    it "returns no company" do
      sign_in(user)
      get search_companies_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
