Rails.application.config.middleware.use OmniAuth::Builder do
  # To get the Steam Web API key, you'll need to request one here:
  # https://steamcommunity.com/dev/apikey
  provider :steam, ENV['STEAM_WEB_API_KEY']
end
