require 'rails_helper'

RSpec.describe "Releases", type: :feature do
  describe "releases index" do
    let!(:release) { create(:release) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(releases_path)
      expect(page).to have_link(href: release_path(release))
      expect(page).to have_no_link(href: new_release_path)
    end

    it "with user" do
      sign_in(user)

      visit(releases_path)
      expect(page).to have_link(href: release_path(release))
      expect(page).to have_link(href: new_release_path)
    end

    it "with moderator" do
      sign_in(moderator)

      visit(releases_path)
      expect(page).to have_link(href: release_path(release))
      expect(page).to have_link(href: new_release_path)
    end
  end

  describe "release page" do
    let!(:release) { create(:release) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(release_path(release))
      expect(page).to have_content(release.name)
      expect(page).to have_no_link(href: edit_release_path(release))
    end

    it "with user" do
      sign_in(user)

      visit(release_path(release))
      expect(page).to have_content(release.name)
      find('#actions-dropdown').click
      expect(page).to have_link(href: edit_release_path(release))
    end

    it "with moderator" do
      sign_in(moderator)

      visit(release_path(release))
      expect(page).to have_content(release.name)
      find('#actions-dropdown').click
      expect(page).to have_link(href: edit_release_path(release))
    end
  end

  describe "delete release" do
    let!(:release) { create(:release) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }

    it "lets user delete it" do
      sign_in(user)
      visit(release_path(release))

      find('#actions-dropdown').click
      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(releases_path)
      expect(page).to have_no_content(release.name)
    end

    it "lets moderator delete it" do
      sign_in(moderator)
      visit(release_path(release))

      find('#actions-dropdown').click
      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(releases_path)
      expect(page).to have_no_content(release.name)
    end
  end
end
