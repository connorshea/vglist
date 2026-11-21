# frozen_string_literal: true

# The games for the home page's "Recently added to libraries" shelf: the games
# people have most recently added to their libraries, newest first.
#
# Each game appears once, at its most recent addition. Only public, unbanned
# users' libraries count, matching what anyone can see on their profiles.
#
# A Steam import adds hundreds of games at once, so taken plainly the newest
# entries would often all be one person's library. Each user contributes at
# most PER_USER games, so the shelf shows what several people have been
# adding.
#
# The IDs are cached for EXPIRES_IN, the same as the public response cache in
# front of them. The games themselves are loaded fresh on every request, so a
# signed-in user's library badges are always current and a deleted game just
# drops out of the list.
module RecentLibraryAdditions
  # The most games that can be asked for at once: two rows of six on the home
  # page.
  MAX = 12

  # How many IDs are cached. More than MAX, so that a game deleted since the
  # list was cached is replaced by the next one and a full shelf stays full.
  CACHED = MAX * 2

  # The most games one user can contribute.
  PER_USER = 2

  # Library entries are read newest first in batches of BATCH_SIZE, stopping
  # once CACHED games are found or MAX_SCANNED entries have been read. The
  # bound keeps a run of huge imports from turning this into a scan of the
  # whole table; it just leaves the shelf shorter.
  BATCH_SIZE = 500
  MAX_SCANNED = 10_000

  EXPIRES_IN = 5.minutes

  CACHE_KEY = 'home_recent_library_additions/v1'

  module_function

  # @param limit [Integer] How many games to return, at most MAX.
  # @return [ActiveRecord::Relation<Game>] The games, most recently added first.
  def games(limit)
    # Looks up all the cached IDs before limiting, so a game deleted since the
    # list was cached is replaced by the next one instead of leaving a gap.
    ids = game_ids
    Game.where(id: ids).in_order_of(:id, ids).limit(limit.clamp(0, MAX))
  end

  # @return [Array<Integer>] The IDs of up to CACHED games, most recently
  #   added first.
  def game_ids
    Rails.cache.fetch(CACHE_KEY, expires_in: EXPIRES_IN, race_condition_ttl: 1.minute) { recent_ids }
  end

  # Walks library entries newest first, using the (created_at, id) index on
  # game_purchases, and resumes each batch after the last entry read.
  #
  # @return [Array<Integer>]
  def recent_ids
    ids = []
    seen = Set.new
    per_user = Hash.new(0)
    cursor = nil
    scanned = 0

    while scanned < MAX_SCANNED
      batch = entries_before(cursor).limit(BATCH_SIZE).pluck(:game_id, :user_id, :created_at, :id)

      batch.each do |game_id, user_id, _created_at, _id|
        next if per_user[user_id] >= PER_USER
        next unless seen.add?(game_id)

        per_user[user_id] += 1
        ids << game_id
        return ids if ids.size >= CACHED
      end

      break if batch.size < BATCH_SIZE

      scanned += batch.size
      cursor = batch.last.last(2)
    end

    ids
  end

  # @param cursor [Array(Time, Integer), nil] The created_at and id of the last
  #   entry already read.
  # @return [ActiveRecord::Relation<GamePurchase>] Public users' library
  #   entries older than the cursor, newest first.
  def entries_before(cursor)
    entries = GamePurchase.joins(:user)
                          .merge(User.public_and_unbanned)
                          .order(created_at: :desc, id: :desc)
    return entries if cursor.nil?

    entries.where('(game_purchases.created_at, game_purchases.id) < (?, ?)', *cursor)
  end
end
