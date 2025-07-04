require 'rails_helper'

RSpec.describe "Series", type: :feature do
  describe "series index" do
    let!(:series) { create(:series) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(series_index_path)
      expect(page).to have_link(href: series_path(series))
      expect(page).to have_no_link(href: new_series_path)
    end

    it "with user" do
      sign_in(user)

      visit(series_index_path)
      expect(page).to have_link(href: series_path(series))
      expect(page).to have_no_link(href: new_series_path)
    end

    it "with moderator" do
      sign_in(moderator)

      visit(series_index_path)
      expect(page).to have_link(href: series_path(series))
      expect(page).to have_link(href: new_series_path)
    end
  end

  describe "series page" do
    let!(:series) { create(:series) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(series_path(series))
      expect(page).to have_content(series.name)
      expect(page).to have_no_link(href: edit_series_path(series))
    end

    it "with user" do
      sign_in(user)

      visit(series_path(series))
      expect(page).to have_content(series.name)
      expect(page).to have_no_link(href: edit_series_path(series))
    end

    it "with moderator" do
      sign_in(moderator)

      visit(series_path(series))
      expect(page).to have_content(series.name)
      expect(page).to have_link(href: edit_series_path(series))
    end
  end

  describe "new series page" do
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid series data" do
      sign_in(moderator)

      visit(new_series_path)
      within('#new_series') do
        fill_in('series[name]', with: 'Half-Life')
        fill_in('series[wikidata_id]', with: 'Q123')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#new_series')
    end
  end

  describe "edit series page" do
    let!(:series) { create(:series) }
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid series data" do
      sign_in(moderator)

      visit(edit_series_path(series))
      within("#edit_series_#{series.id}") do
        fill_in('series[name]', with: 'Half-Life')
      end
      click_button 'Submit'

      expect(page).to have_current_path(series_path(series))
    end
  end

  describe "delete series" do
    let!(:series) { create(:series) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }

    it "does not let user delete it" do
      sign_in(user)
      visit(series_path(series))

      expect(page).to have_no_link('Delete')
    end

    it "lets moderator delete it" do
      sign_in(moderator)
      visit(series_path(series))

      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(series_index_path)
      expect(page).to have_no_content(series.name)
    end
  end
end
