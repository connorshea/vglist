require 'rails_helper'

RSpec.describe "Engines", type: :feature do
  describe "engines index" do
    let!(:engine) { create(:engine) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(engines_path)
      expect(page).to have_link(href: engine_path(engine))
      expect(page).to have_no_link(href: new_engine_path)
    end

    it "with user" do
      sign_in(user)

      visit(engines_path)
      expect(page).to have_link(href: engine_path(engine))
      expect(page).to have_no_link(href: new_engine_path)
    end

    it "with moderator" do
      sign_in(moderator)

      visit(engines_path)
      expect(page).to have_link(href: engine_path(engine))
      expect(page).to have_link(href: new_engine_path)
    end
  end

  describe "engine page" do
    let!(:engine) { create(:engine) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(engine_path(engine))
      expect(page).to have_content(engine.name)
      expect(page).to have_no_link(href: edit_engine_path(engine))
    end

    it "with user" do
      sign_in(user)

      visit(engine_path(engine))
      expect(page).to have_content(engine.name)
      expect(page).to have_no_link(href: edit_engine_path(engine))
    end

    it "with moderator" do
      sign_in(moderator)

      visit(engine_path(engine))
      expect(page).to have_content(engine.name)
      expect(page).to have_link(href: edit_engine_path(engine))
    end
  end

  describe "new engine page" do
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid engine data" do
      sign_in(moderator)

      visit(new_engine_path)
      within('#new_engine') do
        fill_in('engine[name]', with: 'GoldSrc')
        fill_in('engine[wikidata_id]', with: 'Q123')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#new_engine')
    end
  end

  describe "edit engine page" do
    let!(:engine) { create(:engine) }
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid engine data" do
      sign_in(moderator)

      visit(edit_engine_path(engine))
      within("#edit_engine_#{engine.id}") do
        fill_in('engine[name]', with: 'GoldSrc')
      end
      click_button 'Submit'

      expect(page).to have_current_path(engine_path(engine))
    end
  end

  describe "delete engine" do
    let!(:engine) { create(:engine) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }

    it "does not let user delete it" do
      sign_in(user)
      visit(engine_path(engine))

      expect(page).to have_no_link('Delete')
    end

    it "lets moderator delete it" do
      sign_in(moderator)
      visit(engine_path(engine))

      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(engines_path)
      expect(page).to have_no_content(engine.name)
    end
  end
end
