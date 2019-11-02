# typed: false
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
    let(:company_with_everything) { create(:company_with_everything) }

    it "returns http success" do
      get company_path(id: company.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for company that has everything" do
      get company_path(id: company_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_company_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get new_company_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_company_path" do
    let(:user) { create(:confirmed_user) }
    let(:company) { create(:company) }
    let(:company_with_everything) { create(:company_with_everything) }

    it "returns http success" do
      sign_in(user)
      get edit_company_path(id: company.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for company that has everything" do
      sign_in(user)
      get edit_company_path(id: company_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST companies_path" do
    let(:user) { create(:confirmed_user) }
    let(:company_attributes) { attributes_for(:company) }

    it "creates a new company" do
      sign_in(user)
      expect do
        post companies_path, params: { company: company_attributes }
      end.to change(Company, :count).by(1)
    end

    it "fails to create a new company" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      company_attributes[:name] = long_name
      post companies_path, params: { company: company_attributes }
      expect(response.body).to include('Unable to create company.')
    end
  end

  describe "PUT company_path" do
    let(:user) { create(:confirmed_user) }
    let!(:company) { create(:company) }
    let(:company_attributes) { attributes_for(:company) }

    it "updates company Wikidata ID" do
      sign_in(user)
      company_attributes[:wikidata_id] = 12_345
      put company_path(id: company.id), params: { company: company_attributes }
      expect(company.reload.wikidata_id).to be(12_345)
    end

    it "fails to update company" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      company_attributes[:name] = long_name
      put company_path(id: company.id), params: { company: company_attributes }
      expect(response.body).to include('Unable to update company.')
    end
  end

  describe "DELETE company_path" do
    let(:user) { create(:confirmed_user) }
    let!(:company) { create(:company) }

    it "deletes a company" do
      sign_in(user)
      expect do
        delete company_path(id: company.id)
      end.to change(Company, :count).by(-1)
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

    it "returns no company when no query is given" do
      sign_in(user)
      get search_companies_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end
end
