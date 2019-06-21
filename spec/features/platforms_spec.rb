# typed: false
require 'rails_helper'

RSpec.describe "Platforms", type: :feature do
  describe "platforms index" do
    let!(:platform) { create(:platform) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(platforms_path)
      expect(page).to have_link(href: platform_path(platform))
      expect(page).to have_no_link(href: new_platform_path)
    end

    it "with user" do
      sign_in(user)

      visit(platforms_path)
      expect(page).to have_link(href: platform_path(platform))
      expect(page).to have_no_link(href: new_platform_path)
    end

    it "with moderator" do
      sign_in(moderator)

      visit(platforms_path)
      expect(page).to have_link(href: platform_path(platform))
      expect(page).to have_link(href: new_platform_path)
    end
  end

  describe "platform page" do
    let!(:platform) { create(:platform) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(platform_path(platform))
      expect(page).to have_content(platform.name)
      expect(page).to have_no_link(href: edit_platform_path(platform))
    end

    it "with user" do
      sign_in(user)

      visit(platform_path(platform))
      expect(page).to have_content(platform.name)
      expect(page).to have_no_link(href: edit_platform_path(platform))
    end

    it "with moderator" do
      sign_in(moderator)

      visit(platform_path(platform))
      expect(page).to have_content(platform.name)
      expect(page).to have_link(href: edit_platform_path(platform))
    end
  end

  describe "new platform page" do
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid platform data" do
      sign_in(moderator)

      visit(new_platform_path)
      within('#new_platform') do
        fill_in('platform[name]', with: 'Nintendo Switch')
        fill_in('platform[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#new_platform')
    end
  end

  describe "edit platform page" do
    let!(:platform) { create(:platform) }
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid platform data" do
      sign_in(moderator)

      visit(edit_platform_path(platform))
      within("#edit_platform_#{platform.id}") do
        fill_in('platform[name]', with: 'Nintendo Switch')
        fill_in('platform[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_current_path(platform_path(platform))
    end
  end

  describe "delete platform" do
    let!(:platform) { create(:platform) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }

    it "does not let user delete it" do
      sign_in(user)
      visit(platform_path(platform))

      expect(page).to have_no_link('Delete')
    end

    it "lets moderator delete it" do
      sign_in(moderator)
      visit(platform_path(platform))

      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(platforms_path)
      expect(page).to have_no_content(platform.name)
    end
  end
end
