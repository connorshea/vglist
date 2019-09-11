# typed: strict

SorbetRails.configure do |config|
  config.enabled_gem_plugins = [
    :kaminari,
    :pg_search,
    :friendly_id
  ]
  # Include the Devise Controller Helpers in helpers.rbi.
  config.extra_helper_includes = [
    'Devise::Controllers::Helpers'
  ]
end
