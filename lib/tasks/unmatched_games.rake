# typed: false
# rubocop:disable Rails/PluckInWhere
namespace :vglist do
  namespace :unmatched_games do
    desc "Clean out the unmatched_games table."
    task clean: :environment do
      puts 'Cleaning out UnmatchedGames...'

      before_count = UnmatchedGame.count

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

      puts "Unmatched Games cleaned. #{before_count - UnmatchedGame.count} records removed. #{UnmatchedGame.count} records remaining."
    end
  end
end
# rubocop:enable Rails/PluckInWhere
