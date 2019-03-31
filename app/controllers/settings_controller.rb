class SettingsController < ApplicationController
  # Profile things
  def profile
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  # Account settings
  def account
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  def steam_api_test
    json = JSON.parse(URI.open("https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{current_user.uid}&include_appinfo=1&include_played_free_games=1").read)

    steam_games = json.dig('response', 'games')
    unmatched_games = []

    steam_games&.each do |steam_game|
      game = Game.find_by(steam_app_id: steam_game['appid'])
      # Convert playtime from minutes to hours, rounded to one decimal place.
      hours_played = (steam_game['playtime_forever'].to_f / 60).round(1)
      if game.nil?
        unmatched_games << steam_game
        next
      end

      GamePurchase.find_or_create_by!(
        game_id: game.id,
        user_id: current_user[:id],
        hours_played: hours_played
      )
    end

    skip_authorization
    respond_to do |format|
      format.json { render json: unmatched_games.to_json }
    end
  end
end
