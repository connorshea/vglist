module FeatureTestHelper
  def click_active_dropdown_option
    # the debounce on the search for the vue single-select component is 250ms.
    # Without this, nothing will show up for results.
    sleep 0.3
    within '.vue-select[data-state="open"] .menu' do
      # Click the first option (vue3-select-component auto-focuses first option,
      # but timing can cause the focused class to not be present yet)
      first('.menu-option').click
    end
  end
end
