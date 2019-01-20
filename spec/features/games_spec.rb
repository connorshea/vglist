require 'rails_helper'

RSpec.feature "Games", type: :feature do
  describe "games index" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    scenario "with no user" do
      visit(games_path)
      expect(page).to have_link(href: game_path(game))
      expect(page).not_to have_link(href: new_game_path)
    end

    scenario "with user" do
      sign_in(user)

      visit(games_path)
      expect(page).to have_link(href: game_path(game))
      expect(page).to have_link(href: new_game_path)
    end
  end

  describe "game page" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    scenario "with no user" do
      visit(game_path(game))
      expect(page).to have_content(game.name)
      expect(page).not_to have_link(href: edit_game_path(game))
    end

    scenario "with user" do
      sign_in(user)

      visit(game_path(game))
      expect(page).to have_content(game.name)
      expect(page).to have_link(href: edit_game_path(game))
    end
  end
end
