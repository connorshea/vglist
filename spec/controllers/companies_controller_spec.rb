require 'rails_helper'

RSpec.describe CompaniesController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    let(:company) { create(:company) }

    it "returns http success" do
      get :show, params: { id: company.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "returns http found" do
      post :create, params: {
        name: "Company",
        description: "Lorem ipsum"
      }
      expect(response).to have_http_status(:found)
    end
  end

  describe "POST #update" do
    let(:company) { create(:company) }

    it "returns http found" do
      post :update, params: {
        id: company.id,
        name: "Company",
        description: "Lorem ipsum"
      }
      expect(response).to have_http_status(:found)
    end
  end
end
