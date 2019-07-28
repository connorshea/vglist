# typed: false
require 'rails_helper'

RSpec.describe "Companies", type: :feature do
  describe "companies index" do
    let!(:company) { create(:company) }
    let(:user) { create(:confirmed_user) }

    it "with no user" do
      visit(companies_path)
      expect(page).to have_link(href: company_path(company))
      expect(page).to have_no_link(href: new_company_path)
    end

    it "with user" do
      sign_in(user)

      visit(companies_path)
      expect(page).to have_link(href: company_path(company))
      expect(page).to have_link(href: new_company_path)
    end
  end

  describe "company page" do
    let!(:company) { create(:company) }
    let(:user) { create(:confirmed_user) }

    it "with no user" do
      visit(company_path(company))
      expect(page).to have_content(company.name)
      expect(page).to have_no_link(href: edit_company_path(company))
    end

    it "with user" do
      sign_in(user)

      visit(company_path(company))
      expect(page).to have_content(company.name)
      expect(page).to have_link(href: edit_company_path(company))
    end
  end

  describe "new company page", js: true do
    let(:user) { create(:confirmed_user) }

    it "accepts valid company data" do
      sign_in(user)

      visit(new_company_path)
      within('#new_company') do
        fill_in('company[name]', with: 'Half-Life')
        fill_in('company[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#new_company')
    end
  end

  describe "edit company page", js: true do
    let!(:company) { create(:company) }
    let(:user) { create(:confirmed_user) }

    it "accepts valid company data" do
      sign_in(user)

      visit(edit_company_path(company))
      within("#edit_company_#{company.id}") do
        fill_in('company[name]', with: 'Half-Life')
        fill_in('company[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_current_path(company_path(company))
    end
  end

  describe "delete company" do
    let!(:company) { create(:company) }
    let(:user) { create(:confirmed_user) }

    it "accepts valid company data" do
      sign_in(user)
      visit(company_path(company))

      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(companies_path)
      expect(page).to have_no_content(company.name)
    end
  end
end
