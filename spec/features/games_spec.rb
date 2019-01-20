require 'rails_helper'

RSpec.describe "Games", type: :feature do
  describe "games index" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    it "with no user" do
      visit(games_path)
      expect(page).to have_link(href: game_path(game))
      expect(page).not_to have_link(href: new_game_path)
    end

    it "with user" do
      sign_in(user)

      visit(games_path)
      expect(page).to have_link(href: game_path(game))
      expect(page).to have_link(href: new_game_path)
    end
  end

  describe "game page" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    it "with no user" do
      visit(game_path(game))
      expect(page).to have_content(game.name)
      expect(page).not_to have_link(href: edit_game_path(game))
    end

    it "with user" do
      sign_in(user)

      visit(game_path(game))
      expect(page).to have_content(game.name)
      expect(page).to have_link(href: edit_game_path(game))
    end
  end

  describe "new game page", js: true do
    let(:user) { create(:confirmed_user) }

    it "accepts valid game data" do
      sign_in(user)

      visit(new_game_path)
      within('#game-form') do
        fill_in('game[name]', with: 'Half-Life')
        fill_in('game[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_no_selector('#game-form')
    end
  end

  describe "edit game page", js: true do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    it "accepts valid game data" do
      sign_in(user)

      visit(edit_game_path(game))
      within('#game-form') do
        fill_in('game[name]', with: 'Half-Life')
        fill_in('game[description]', with: 'Lorem ipsum')
      end
      click_button 'Submit'

      expect(page).to have_current_path(game_path(game))
    end
  end
end
