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
end
