# typed: strict
require 'set'

class SteamImportService
  extend T::Sig

  sig { returns(User) }
  attr_reader :user

  sig { returns(T.nilable(ExternalAccount)) }
  attr_accessor :steam_account

  sig { params(user: User, update_hours: T::Boolean).void }
  def initialize(user:, update_hours: false)
    @user = user
    @steam_account = T.let(@user.external_account, T.nilable(ExternalAccount))
    @update_hours = update_hours
  end

  class Error < StandardError; end

  class NoGamesError < Error; end

  sig { returns(Result) }
  def call
    raise Error, 'No Steam account.' if steam_account.nil?

    json = JSON.parse(T.must(T.must(URI.open(steam_api_url)).read))

    games = json.dig('response', 'games')

    raise NoGamesError if games.nil?

    blocklisted_steam_app_ids = T.let(SteamBlocklist.pluck(:steam_app_id), T::Array[Integer])

    games.reject! { |game| game['img_logo_url'].blank? }

    # The Steam IDs for all games that were just imported from Steam.
    steam_ids = T.let(games.map { |g| g['appid'].to_i }.uniq, T::Array[Integer])

    # An array of ID pairs for the Steam App ID and vglist game ID, lists all
    # the games that were sent from the Steam API that could be found in our
    # database.
    matching_app_and_game_ids = T.let(SteamAppId.where(app_id: steam_ids).pluck(:app_id, :game_id), T::Array[[Integer, Integer]])
    # A hash that stores all the Steam App IDs and Game IDs.
    matching_app_and_game_ids_hash = matching_app_and_game_ids.each_with_object({}) do |(app_id, game_id), hash|
      hash[app_id] = game_id
    end
    # Get a list of Steam IDs that weren't found in the vglist database.
    missing_ids = T.let(
      steam_ids.to_set - matching_app_and_game_ids.map(&:first).to_set,
      T::Set[Integer]
    )

    create_time = Time.current

    game_structs = T.let(
      games.each
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
      end.to_a,
      T::Array[GameStruct]
    )

    created = []
    updated = []
    if game_structs.any?
      game_structs.each do |game_struct|
        game_purchase = GamePurchase.find_by(game_id: game_struct.game_id, user_id: game_struct.user_id)
        if game_purchase.nil?
          created << GamePurchase.create(game_struct.serialize)
        # If we're intending to update the hours played value, update it!
        elsif @update_hours
          # Skip if there's no change in the hours played.
          next if game_struct.hours_played == game_purchase[:hours_played]

          game_purchase.update(hours_played: game_struct.hours_played)
          updated << game_purchase.reload
        end
      end
    end
    created_purchases = GamePurchase.where(id: created.map { |e| e['id'] })
    updated_purchases = GamePurchase.where(id: updated.map { |e| e['id'] })

    unmatched = missing_ids.to_a.map do |id|
      game = games.find { |g| g['appid'] == id }

      next unless game

      # Exclude any games with Steam IDs that are blocklisted.
      next if blocklisted_steam_app_ids.include?(game['appid'].to_i)

      Unmatched.new(name: game['name'], steam_id: game['appid'])
    end.compact

    Result.new(
      created: created_purchases,
      updated: updated_purchases,
      unmatched: unmatched
    )
  end

  class GameStruct < T::Struct
    const :hours_played, Float
    const :game_id, Integer
    const :user_id, Integer
    const :created_at, ActiveSupport::TimeWithZone
    const :updated_at, ActiveSupport::TimeWithZone
  end

  class Unmatched < T::Struct
    const :name, String
    const :steam_id, Integer
  end

  class Result < T::Struct
    extend T::Sig

    const :created, GamePurchase::RelationType
    const :updated, GamePurchase::RelationType
    const :unmatched, T::Array[Unmatched]

    # Returns the games for all the newly created game purchases.
    sig { returns(Game::RelationType) }
    def added_games
      Game.joins(:game_purchases).merge(created)
    end

    # Returns the games for all the updated game purchases.
    sig { returns(Game::RelationType) }
    def updated_games
      Game.joins(:game_purchases).merge(updated)
    end
  end

  sig { returns(String) }
  def steam_api_url
    "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account_id}&include_appinfo=1&include_played_free_games=1"
  end

  sig { returns(Integer) }
  def steam_account_id
    T.must(steam_account)[:steam_id]
  end
end
