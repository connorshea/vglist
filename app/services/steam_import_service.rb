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
    raise Error, 'no steam account' if steam_account.nil?

    start_time = Time.current

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

    attrs =
      games.each
           .lazy
           .reject { |game| missing_ids.include?(game['appid']) }
           .map do |game_info|
        hours_played = (game_info['playtime_forever'].to_f / 60).round(1)
        {
          hours_played: hours_played,
          game_id: stored_id_hash[game_info['appid']],
          user_id: user.id
        }
      end
    GamePurchase.upsert_all(attrs.to_a)

    unmatched = missing_ids.to_a.take(50).map do |id|
      game = games.find { |g| g['appid'] = id }

      next unless game

      Unmatched.new(name: game['name'], steam_id: game['appid'])
    end.compact

    Result.new(
      added: @user.game_purchases.where('created_at > ?', start_time),
      unmatched: unmatched
    )
  end

  class Unmatched < T::Struct
    const :name, String
    const :steam_id, String
  end

  class Result < T::Struct
    const :added, GamePurchase::RelationType
    const :unmatched, T::Array[Unmatched]
  end

  attr_reader :user

  sig { returns(String) }
  def steam_api_url
    "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account_id}&include_appinfo=1&include_played_free_games=1"
  end

  def steam_account_id
    steam_account.try(:[], :steam_account_id)
  end

  sig { returns(T.nilable(ExternalAccount)) }
  def steam_account
    @steam_account ||=
      ExternalAccount.find_by(user: user, account_type: :steam)
  end
end
