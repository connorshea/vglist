# Service for logging unmatched games from Steam Imports performed by users.
# This lets us keep track of the most common missed games we should add to
# the database/add Steam IDs to, or what Steam apps should be added to a
# blocklist to prevent their addition (DLCs, non-games, test servers, etc.)
class SteamImportLoggingService
  attr_reader :user

  attr_accessor :unmatched_from_import

  def initialize(user:, unmatched_from_import:)
    @user = user
    @unmatched_from_import = unmatched_from_import
  end

  def call
    unmatched_from_import.each do |unmatched_game_struct|
      # Use find_or_create_by to ensure that we don't attempt to create one of
      # these and then error due to uniqueness checks.
      UnmatchedGame.create_with(
        name: unmatched_game_struct.name
      ).find_or_create_by(
        user_id: @user.id,
        external_service_id: unmatched_game_struct.steam_id,
        external_service_name: 'Steam'
      )
    end
  end
end
