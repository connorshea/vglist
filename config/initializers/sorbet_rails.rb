# typed: strict

SorbetRails.configure do |config|
  config.enabled_gem_plugins = [
    :kaminari,
    :pg_search,
    :friendly_id
  ]
end
