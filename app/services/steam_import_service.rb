# typed: true
require 'set'

class SteamImportService
  extend T::Sig

  sig { params(user: User).void }
  def initialize(user)
    @user = user
  end

  class Error < StandardError; end
  class NoGamesError < Error; end

  sig { returns(Result) }
  def call
    raise Error, 'No Steam account.' if steam_account.nil?

    json = JSON.parse(T.must(T.must(URI.open(steam_api_url)).read))

    games = json.dig('response', 'games')

    raise NoGamesError if games.nil?

    games.reject! { |game| game['img_logo_url'].blank? }

    steam_ids = T.cast(
      games.map { |g| g['appid'].to_i }.uniq,
      T::Array[Integer]
    )
    stored_ids = T.cast(SteamAppId.where(app_id: steam_ids).pluck(:app_id, :game_id), T::Array[[Integer, Integer]])
    stored_id_hash = stored_ids.each_with_object({}) do |(app_id, game_id), hash|
      hash[app_id] = game_id
    end
    missing_ids = T.cast(
      steam_ids.to_set - stored_ids.map(&:first).to_set,
      T::Set[Integer]
    )

    create_time = Time.current

    attrs =
      games.each
           .lazy
           .reject { |game| missing_ids.include?(game['appid']) }
           .map do |game_info|
        hours_played = (game_info['playtime_forever'].to_f / 60).round(1)
        {
          hours_played: hours_played,
          game_id: stored_id_hash[game_info['appid']],
          user_id: user.id,
          created_at: create_time,
          updated_at: create_time
        }
      end
    attrs = attrs.to_a
    added_purchases =
      if attrs.any?
        inserted = attrs.map { |attr| GamePurchase.find_or_create_by(attr) }
        GamePurchase.where(id: inserted.map { |e| e['id'] })
      else
        GamePurchase.none
      end

    unmatched = missing_ids.to_a.map do |id|
      game = games.find { |g| g['appid'] == id }

      next unless game

      Unmatched.new(name: game['name'], steam_id: game['appid'])
    end.compact

    Result.new(
      added: added_purchases,
      unmatched: unmatched
    )
  end

  class Unmatched < T::Struct
    const :name, String
    const :steam_id, Integer
  end

  class Result < T::Struct
    const :added, GamePurchase::RelationType
    const :unmatched, T::Array[Unmatched]

    def added_games
      Game.joins(:game_purchases).merge(added)
    end
  end

  attr_reader :user

  sig { returns(String) }
  def steam_api_url
    "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account_id}&include_appinfo=1&include_played_free_games=1"
  end

  def steam_account_id
    steam_account.try(:[], :steam_id)
  end

  sig { returns(T.nilable(ExternalAccount)) }
  def steam_account
    @steam_account ||= user.external_account
  end
end
