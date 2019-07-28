# typed: false
require 'rails_helper'

RSpec.describe "Genres", type: :feature do
  describe "genres index" do
    let!(:genre) { create(:genre) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(genres_path)
      expect(page).to have_link(href: genre_path(genre))
      expect(page).to have_no_link(href: new_genre_path)
    end

    it "with user" do
      sign_in(user)

      visit(genres_path)
      expect(page).to have_link(href: genre_path(genre))
      expect(page).to have_no_link(href: new_genre_path)
    end

    it "with moderator" do
      sign_in(moderator)

      visit(genres_path)
      expect(page).to have_link(href: genre_path(genre))
      expect(page).to have_link(href: new_genre_path)
    end
  end

  describe "genre page" do
    let!(:genre) { create(:genre) }
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }

    it "with no user" do
      visit(genre_path(genre))
      expect(page).to have_content(genre.name)
      expect(page).to have_no_link(href: edit_genre_path(genre))
    end

    it "with user" do
      sign_in(user)

      visit(genre_path(genre))
      expect(page).to have_content(genre.name)
      expect(page).to have_no_link(href: edit_genre_path(genre))
    end

    it "with moderator" do
      sign_in(moderator)

      visit(genre_path(genre))
      expect(page).to have_content(genre.name)
      expect(page).to have_link(href: edit_genre_path(genre))
    end
  end

  describe "new genre page" do
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid genre data" do
      sign_in(moderator)

      visit(new_genre_path)
      within('#new_genre') do
        fill_in('genre[name]', with: 'FPS')
        fill_in('genre[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#new_genre')
    end
  end

  describe "edit genre page" do
    let!(:genre) { create(:genre) }
    let(:moderator) { create(:confirmed_moderator) }

    it "accepts valid genre data" do
      sign_in(moderator)

      visit(edit_genre_path(genre))
      within("#edit_genre_#{genre.id}") do
        fill_in('genre[name]', with: 'FPS')
        fill_in('genre[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_current_path(genre_path(genre))
    end
  end

  describe "delete genre" do
    let!(:genre) { create(:genre) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }

    it "does not let user delete it" do
      sign_in(user)
      visit(genre_path(genre))

      expect(page).to have_no_link('Delete')
    end

    it "lets moderator delete it" do
      sign_in(moderator)
      visit(genre_path(genre))

      accept_alert do
        click_link 'Delete'
      end

      expect(page).to have_current_path(genres_path)
      expect(page).to have_no_content(genre.name)
    end
  end
end
