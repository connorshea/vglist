# typed: strict

require Rails.root.join('lib/cursed_rbi_plugin')

SorbetRails::ModelRbiFormatter.register_plugin(CursedRbiPlugin)

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

# Load SorbetRailsHack to add typed_require.
ActiveSupport.on_load(:action_controller) do
  require Rails.root.join('lib/sorbet_rails_hack')
  ActionController::Parameters.include SorbetRailsHack
end
