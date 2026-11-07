# frozen_string_literal: true

# Compares two users' game libraries in SQL: which games they both own, which
# only one of them owns, and how far apart their ratings are for the games
# they have in common.
#
# The old compare page loaded both libraries in full and merged them in the
# browser, which got slow with two 1,000+ game libraries. Doing it here means
# the client only ever loads one page of each list.
#
# This doesn't check whether anyone is allowed to see either library; that's
# the caller's job (see `UserPolicy#compare?`).
class LibraryComparison
  # The alias for user B's game purchase in the `in_common` relation.
  OTHER = 'other_purchases'

  # The signed difference between the two ratings: positive when user A rated
  # the game higher, negative when user B did, nil unless both rated it.
  RATING_DIFFERENCE_SQL = "game_purchases.rating - #{OTHER}.rating".freeze

  # Each sort breaks ties on the game name and then on `id`, so that the
  # ordering is total. Cursor-based pagination walks the relation by offset,
  # so a partial ordering would let rows repeat or vanish between pages.
  IN_COMMON_SORTS = {
    'rating_gap' => "ABS(#{RATING_DIFFERENCE_SQL}) DESC NULLS LAST",
    'game_name' => nil,
    'user_a_rating' => 'game_purchases.rating DESC NULLS LAST',
    'user_b_rating' => "#{OTHER}.rating DESC NULLS LAST"
  }.freeze

  attr_reader :user_a, :user_b

  # @param user_a [User]
  # @param user_b [User]
  def initialize(user_a, user_b)
    @user_a = user_a
    @user_b = user_b
  end

  # User A's game purchases for the games user B also owns. Each record also
  # has `other_purchase_id` (user B's game purchase for the same game) and
  # `rating_difference` (see `RATING_DIFFERENCE_SQL`) selected onto it.
  #
  # @param search [String, nil] Only include games whose name contains this.
  # @param both_rated [Boolean] Only include games both users have rated.
  # @param sort_by [String, nil] One of the keys of `IN_COMMON_SORTS`.
  # @return [ActiveRecord::Relation<GamePurchase>]
  def in_common(search: nil, both_rated: false, sort_by: nil)
    purchases = in_common_base
                .select('game_purchases.*', "#{OTHER}.id AS other_purchase_id", "#{RATING_DIFFERENCE_SQL} AS rating_difference")
    purchases = purchases.with_game_name_matching(search) if search.present?
    purchases = purchases.where.not(rating: nil).where.not(OTHER => { rating: nil }) if both_rated

    order = IN_COMMON_SORTS.fetch(sort_by || 'rating_gap')
    purchases.joins(:game).order(*[order, 'games.name ASC', 'game_purchases.id ASC'].compact.map { |clause| Arel.sql(clause) })
  end

  # User A's game purchases for the games user B doesn't own.
  #
  # @return [ActiveRecord::Relation<GamePurchase>]
  def only_a
    user_a.game_purchases.where.not(game_id: user_b.game_purchases.select(:game_id))
  end

  # User B's game purchases for the games user A doesn't own.
  #
  # @return [ActiveRecord::Relation<GamePurchase>]
  def only_b
    user_b.game_purchases.where.not(game_id: user_a.game_purchases.select(:game_id))
  end

  # @return [Integer]
  def in_common_count
    summary[:in_common_count]
  end

  # @return [Integer]
  def only_a_count
    summary[:user_a_count] - in_common_count
  end

  # @return [Integer]
  def only_b_count
    summary[:user_b_count] - in_common_count
  end

  # The number of games in common that both users have rated.
  #
  # @return [Integer]
  def both_rated_count
    summary[:both_rated_count]
  end

  # The mean absolute difference between the two users' ratings, over the
  # games in common that both of them have rated. nil when there are none.
  #
  # @return [Float, nil]
  def average_rating_gap
    summary[:average_rating_gap]
  end

  private

  def in_common_base
    sql = "INNER JOIN game_purchases #{OTHER} ON #{OTHER}.game_id = game_purchases.game_id AND #{OTHER}.user_id = ?"
    join = GamePurchase.sanitize_sql_array([sql, user_b.id])
    user_a.game_purchases.joins(join)
  end

  # Every count in one pass over each library, so the header doesn't cost a
  # query per number.
  def summary
    @summary ||= begin
      in_common_count, both_rated_count, average_gap = in_common_base.pick(
        Arel.sql('COUNT(*)'),
        Arel.sql("COUNT(#{RATING_DIFFERENCE_SQL})"),
        Arel.sql("AVG(ABS(#{RATING_DIFFERENCE_SQL}))")
      )

      {
        in_common_count: in_common_count,
        both_rated_count: both_rated_count,
        average_rating_gap: average_gap&.to_f&.round(1),
        user_a_count: user_a.game_purchases.count,
        user_b_count: user_b.game_purchases.count
      }
    end
  end
end
