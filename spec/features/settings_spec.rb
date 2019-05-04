require 'rails_helper'

RSpec.describe "Settings", type: :feature do
  describe "profile settings" do
    let(:user) { create(:confirmed_user) }

    it "with user" do
      sign_in(user)

      visit(settings_path)
      within(".bio-form") do
        fill_in('user[bio]', with: 'New bio!')
      end
      click_button 'Submit'

      expect(page).to have_content("#{user.username} was successfully updated.")
      expect(user.reload.bio).to eql('New bio!')
    end

    it "with no user" do
      visit(settings_path)
      expect(page).not_to have_current_path(settings_path)
      expect(page).to have_content("You are not authorized to perform this action.")
    end
  end

  describe "account settings" do
    let(:user) { create(:confirmed_user) }

    it "with user" do
      sign_in(user)

      visit(settings_account_path)
      within('#new_user') do
        fill_in('user[password]', with: 'newpassword')
        fill_in('user[password_confirmation]', with: 'newpassword')
        fill_in('user[current_password]', with: user.password)
      end
      click_button 'Update'

      expect(page).to have_content('Your account has been updated successfully.')
    end

    it "with no user" do
      visit(settings_account_path)
      expect(page).not_to have_current_path(settings_account_path)
      expect(page).to have_content("You are not authorized to perform this action.")
    end
  end
end
