require 'net/http'

class SteamImportService
  attr_reader :user

  attr_accessor :steam_account

  def initialize(user:, update_hours: false)
    @user = user
    @steam_account = @user.external_account
    @update_hours = update_hours
  end

  class Error < StandardError; end

  class NoGamesError < Error; end

  def call
    raise Error, 'No Steam account.' if steam_account.nil?

    uri = URI(steam_api_url)
    response = Net::HTTP.get_response(uri)

    raise Error, 'Steam API Request failed.' unless response.is_a?(Net::HTTPSuccess)

    json = JSON.parse(response.body)
    games = json.dig('response', 'games')

    raise NoGamesError if games.nil?

    blocklisted_steam_app_ids = SteamBlocklist.pluck(:steam_app_id)

    # Filter out games with no icon, as they tend to be random server software and such.
    games.reject! { |game| game['img_icon_url'].blank? }

    # The Steam IDs for all games that were just imported from Steam.
    steam_ids = games.map { |g| g['appid'].to_i }.uniq

    # An array of ID pairs for the Steam App ID and vglist game ID, lists all
    # the games that were sent from the Steam API that could be found in our
    # database.
    matching_app_and_game_ids = SteamAppId.where(app_id: steam_ids).pluck(:app_id, :game_id)
    # A hash that stores all the Steam App IDs and Game IDs.
    matching_app_and_game_ids_hash = matching_app_and_game_ids.each_with_object({}) do |(app_id, game_id), hash|
      hash[app_id] = game_id
    end
    # Get a list of Steam IDs that weren't found in the vglist database.
    missing_ids = steam_ids.to_set - matching_app_and_game_ids.map(&:first).to_set

    create_time = Time.current

    game_structs = games.each
                        .lazy
                        .reject { |game| missing_ids.include?(game['appid']) }
                        .map do |game_info|
      GameStruct.new(
        hours_played: (game_info['playtime_forever'].to_f / 60).round(1),
        game_id: matching_app_and_game_ids_hash[game_info['appid']],
        user_id: user.id,
        created_at: create_time,
        updated_at: create_time
      )
    end.to_a

    created = []
    updated = []
    if game_structs.any?
      game_structs.each do |game_struct|
        game_purchase = GamePurchase.find_by(game_id: game_struct.game_id, user_id: game_struct.user_id)
        if game_purchase.nil?
          created << GamePurchase.create(**game_struct.to_h)
        # If we're intending to update the hours played value, update it!
        elsif @update_hours
          # Skip if there's no change in the hours played.
          next if game_struct.hours_played == game_purchase[:hours_played]

          game_purchase.update(hours_played: game_struct.hours_played)
          updated << game_purchase.reload
        end
      end
    end
    created_purchases = GamePurchase.where(id: created.pluck('id'))
    updated_purchases = GamePurchase.where(id: updated.pluck('id'))

    unmatched = missing_ids.to_a.filter_map do |id|
      game = games.find { |g| g['appid'] == id }

      next unless game

      # Exclude any games with Steam IDs that are blocklisted.
      next if blocklisted_steam_app_ids.include?(game['appid'].to_i)

      Unmatched.new(name: game['name'], steam_id: game['appid'])
    end

    # Log any unmatched games that we tried to import, for later.
    SteamImportLoggingService.new(user: user, unmatched_from_import: unmatched).call

    Result.new(
      created: created_purchases,
      updated: updated_purchases,
      unmatched: unmatched
    )
  end

  GameStruct = Struct.new(:hours_played, :game_id, :user_id, :created_at, :updated_at)

  Unmatched = Struct.new(:name, :steam_id)

  Result = Struct.new(:created, :updated, :unmatched) do
    # Returns the games for all the newly created game purchases.
    def added_games
      Game.joins(:game_purchases).merge(created)
    end

    # Returns the games for all the updated game purchases.
    def updated_games
      Game.joins(:game_purchases).merge(updated)
    end
  end

  def steam_api_url
    "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account_id}&include_appinfo=1&include_played_free_games=1"
  end

  def steam_account_id
    steam_account[:steam_id]
  end
end
