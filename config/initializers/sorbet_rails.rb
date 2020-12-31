# typed: strict

require Rails.root.join('lib/cursed_rbi_plugin')
require Rails.root.join('lib/pg_search_custom_plugin')
require Rails.root.join('lib/friendly_id_custom_plugin')

SorbetRails::ModelRbiFormatter.register_plugin(CursedRbiPlugin)
SorbetRails::ModelRbiFormatter.register_plugin(PgSearchCustomPlugin)
SorbetRails::ModelRbiFormatter.register_plugin(FriendlyIdCustomPlugin)

SorbetRails.configure do |config|
  config.enabled_gem_plugins = [
    :kaminari,
    :pg_search,
    :friendly_id
  ]
  # Include the Devise Controller Helpers in helpers.rbi.
  config.extra_helper_includes = [
    'Devise::Controllers::Helpers',
    'InlineSvg::ActionView::Helpers'
  ]
end

# Load SorbetRailsHack to add typed_require.
ActiveSupport.on_load(:action_controller) do
  require Rails.root.join('lib/sorbet_rails_hack')
  ActionController::Parameters.include SorbetRailsHack
end
