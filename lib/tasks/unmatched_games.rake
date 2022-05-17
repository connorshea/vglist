# typed: false
namespace :vglist do
  namespace :unmatched_games do
    desc "Clean out the unmatched_games table."
    task clean: :environment do
      # Destroy all the UnmatchedGame records where the game is already on the
      # Steam Blocklist.
      UnmatchedGame.where(
        external_service_name: 'Steam',
        external_service_id: SteamBlocklist.pluck(:steam_app_id)
      ).each(&:destroy!)

      # Destroy all the UnmatchedGame records where the game is already
      # represented by a SteamAppId for a game.
      UnmatchedGame.where(
        external_service_name: 'Steam',
        external_service_id: SteamAppId.pluck(:app_id)
      ).each(&:destroy!)

      puts "Unmatched Games updated."
    end
  end
end
