module FeatureTestHelper
  def click_active_dropdown_option
    # the debounce on the search for the vue single-select component is 250ms.
    # Without this, nothing will show up for results.
    sleep 0.3
    within '.v-select.vs--open ul.vs__dropdown-menu' do
      find('li.vs__dropdown-option--highlight').click
    end
  end
end
