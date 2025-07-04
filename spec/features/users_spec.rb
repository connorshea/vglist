require 'rails_helper'

RSpec.describe "Users", type: :feature do
  describe "User page" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:platform) { create(:platform) }

    it "user adds game to library", js: true do
      sign_in(user)
      visit(user_path(user))

      click_button('Add a game to your library')
      fill_in('Game', with: game.name)
      click_active_dropdown_option
      click_button 'Save changes'

      # Make capybara wait until the modal disappears
      expect(page).to have_no_selector('.modal')
      expect(user.games).to include(game)
    end

    it "user adds game with everything to library", js: true do
      sign_in(user)
      visit(user_path(user))

      click_button('Add a game to your library')
      fill_in('Game', with: game.name)
      click_active_dropdown_option
      fill_in('Completion Status', with: 'Unplayed')
      click_active_dropdown_option
      fill_in('Rating', with: '50')
      fill_in('Hours Played', with: '10')
      fill_in('Comments', with: 'Lorem ipsum dolor.')
      fill_in('Platforms', with: platform.name)
      click_active_dropdown_option
      click_button 'Save changes'

      # Make capybara wait until the modal disappears
      expect(page).to have_no_selector('.modal')
      expect(user.game_purchases.first).to have_attributes(
        game_id: game.id,
        user_id: user.id,
        comments: 'Lorem ipsum dolor.',
        rating: 50,
        completion_status: 'unplayed',
        hours_played: 10
      )
      expect(GamePurchasePlatform.count).to eq(1)
    end
  end
end
