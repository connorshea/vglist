module FeatureTestHelper
  def click_active_dropdown_option
    within '.dropdown.open ul.dropdown-menu' do
      find('li.highlight').click
    end
  end
end
