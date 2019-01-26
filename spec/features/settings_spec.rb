require 'rails_helper'

RSpec.describe "Settings", type: :feature do
  describe "settings index" do
    let(:user) { create(:confirmed_user) }

    it "with user" do
      sign_in(user)

      visit(settings_path)
      expect(page).to have_current_path(settings_path)
    end

    it "with no user" do
      visit(settings_path)
      expect(page).not_to have_current_path(settings_path)
      expect(page).to have_content("You are not authorized to perform this action.")
    end
  end
end
