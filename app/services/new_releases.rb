# frozen_string_literal: true

# The games for the home page's "New releases" shelf.
#
# Sorting purely by release date fills the shelf with whatever came out most
# recently, which is often a sparse record with no cover and no links to any
# other site. Instead, this takes the CANDIDATES most recently released games
# and ranks them so that games with a cover come first. Within each group, games
# are ordered by a score that blends how complete the record is with how many
# people own it:
#
#   score = external IDs + OWNER_WEIGHT * ln(1 + owners)
#
# Each external ID (Wikidata, Steam, PCGamingWiki, IGDB, ...) is one point.
# Owners count on a log scale, so the first few owners matter most and a hit
# can't completely bury a well-linked record: with OWNER_WEIGHT 2, 1 owner is
# worth about 1.4 points, 10 owners about 4.8 and 100 owners about 9.2, against
# at most 8 points for IDs. Release date breaks ties.
#
# The ranked IDs are cached for EXPIRES_IN, since the shelf doesn't need to
# change by the minute. The games themselves are loaded fresh on every
# request, so a signed-in user's library badges are always current and a
# deleted game just drops out of the list.
module NewReleases
  # How many of the most recently released games are considered. Bounded so
  # the ranking only ever looks at a small slice of the release_date index.
  CANDIDATES = 100

  # The most games that can be asked for at once, and how many are cached.
  MAX = 12

  EXPIRES_IN = 3.hours

  CACHE_KEY = 'home_new_releases/v2'

  # How much owners count against external IDs. See the score above.
  OWNER_WEIGHT = 2

  # Each external ID column counts as one point of completeness.
  EXTERNAL_ID_COLUMNS = %w[
    wikidata_id
    pcgamingwiki_id
    giantbomb_id
    epic_games_store_id
    gog_id
    igdb_id
    mobygames_id
  ].freeze

  HAS_COVER_SQL = <<~SQL.squish.freeze
    EXISTS (
      SELECT 1 FROM active_storage_attachments
      WHERE active_storage_attachments.record_type = 'Game'
        AND active_storage_attachments.name = 'cover'
        AND active_storage_attachments.record_id = games.id
    )
  SQL

  HAS_STEAM_APP_ID_SQL = <<~SQL.squish.freeze
    EXISTS (SELECT 1 FROM steam_app_ids WHERE steam_app_ids.game_id = games.id)
  SQL

  EXTERNAL_ID_COUNT_SQL = [
    *EXTERNAL_ID_COLUMNS.map { |column| "(games.#{column} IS NOT NULL)::int" },
    "(#{HAS_STEAM_APP_ID_SQL})::int"
  ].join(' + ').freeze

  # Reads the game_purchases_count counter cache rather than counting library
  # entries.
  SCORE_SQL = "(#{EXTERNAL_ID_COUNT_SQL}) + #{OWNER_WEIGHT} * ln(1 + games.game_purchases_count)".freeze

  module_function

  # @param limit [Integer] How many games to return, at most MAX.
  # @return [ActiveRecord::Relation<Game>] The games, best first.
  def games(limit)
    # Looks up all the cached IDs before limiting, so a game deleted since the
    # list was cached is replaced by the next one instead of leaving a gap.
    ids = game_ids
    Game.where(id: ids).in_order_of(:id, ids).limit(limit.clamp(0, MAX))
  end

  # @return [Array<Integer>] The IDs of the top MAX games, best first.
  def game_ids
    Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRES_IN, race_condition_ttl: 1.minute) { ranked_ids }
  end

  # Ranks the candidates in one query. Both EXISTS checks are index lookups
  # (the attachments uniqueness index and steam_app_ids.game_id), run once per
  # candidate.
  #
  # @return [Array<Integer>]
  def ranked_ids
    candidates = Game.recently_released.limit(CANDIDATES).select(:id, :release_date, :game_purchases_count, *EXTERNAL_ID_COLUMNS)

    ranked = Game.from(candidates, :games).order(
      Arel.sql("(#{HAS_COVER_SQL}) DESC"),
      Arel.sql("(#{SCORE_SQL}) DESC"),
      release_date: :desc,
      id: :desc
    )
    ranked.limit(MAX).pluck(:id)
  end
end
