require 'rails_helper'

RSpec.describe "Users", type: :feature do

  describe "User page" do
    let!(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }

    it "user adds game to library", js: true do
      sign_in(user)
      visit(user_path(user))

      click_button('Add a game to your library')
      # Select the first item in the dropdown by pressing Enter.
      fill_in('Game', with: game.name).send_keys(:enter)
      click_button 'Save changes'

      # Make capybara wait until the modal disappears
      expect(page).to have_no_selector('.modal')
      expect(user.reload.games).to include(game)
    end
  end
end
