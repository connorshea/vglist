# frozen_string_literal: true

# The games for the home page's "Upcoming releases" shelf.
#
# Works like NewReleases, looking forward instead of back: it takes the
# CANDIDATES soonest upcoming games within WINDOW and ranks them with the same
# rules, so games with a cover come first and, within each group, games with
# more external IDs and more owners come before sparse records. The release
# date (soonest first) breaks ties.
#
# WINDOW keeps the shelf to games that are actually coming up. Without it, a
# quiet stretch of the calendar would let a well-linked game that's years out
# (often a placeholder date) outrank everything releasing in the next few
# weeks. Six months covers the next couple of release seasons, which is about
# as far ahead as most release dates are firm.
#
# The ranked IDs are cached for EXPIRES_IN. The games are loaded fresh on every
# request, and a game whose release date has arrived since the list was cached
# is dropped, so the shelf never shows a game that's already out.
module UpcomingReleases
  # How many of the soonest upcoming games are considered.
  CANDIDATES = NewReleases::CANDIDATES

  # The most games that can be asked for at once: one row of six on the home
  # page, with room for a second.
  MAX = NewReleases::MAX

  # How many ranked IDs are cached. More than MAX, so that games that are
  # deleted or released since the list was cached are replaced by the next
  # ones and a full shelf stays full.
  CACHED = MAX * 2

  EXPIRES_IN = NewReleases::EXPIRES_IN

  # How far ahead to look. See above.
  WINDOW = 6.months

  CACHE_KEY = 'home_upcoming_releases/v1'

  module_function

  # @param limit [Integer] How many games to return, at most MAX.
  # @return [ActiveRecord::Relation<Game>] The games, best first.
  def games(limit)
    # Looks up all the cached IDs before limiting, so a game deleted or
    # released since the list was cached is replaced by the next one instead
    # of leaving a gap.
    ids = game_ids
    Game.upcoming.unscope(:order).where(id: ids).in_order_of(:id, ids).limit(limit.clamp(0, MAX))
  end

  # @return [Array<Integer>] The IDs of the top CACHED games, best first.
  def game_ids
    Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRES_IN, race_condition_ttl: 1.minute) { ranked_ids }
  end

  # Ranks the candidates in one query, like NewReleases.ranked_ids.
  #
  # @return [Array<Integer>]
  def ranked_ids
    columns = [:id, :release_date, :game_purchases_count, *NewReleases::EXTERNAL_ID_COLUMNS]
    candidates = Game.upcoming.where('release_date < ?', WINDOW.from_now).limit(CANDIDATES).select(*columns)

    ranked = Game.from(candidates, :games).order(
      Arel.sql("(#{NewReleases::HAS_COVER_SQL}) DESC"),
      Arel.sql("(#{NewReleases::SCORE_SQL}) DESC"),
      release_date: :asc,
      id: :asc
    )
    ranked.limit(CACHED).pluck(:id)
  end
end
