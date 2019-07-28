# typed: false
module FeatureTestHelper
  def click_active_dropdown_option
    within '.v-select.vs--open ul.vs__dropdown-menu' do
      find('li.vs__dropdown-option--highlight').click
    end
  end
end
