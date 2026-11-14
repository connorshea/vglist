# frozen_string_literal: true

# Cleans up games whose Wikidata item was deleted or merged on Wikidata (see
# WikidataItemStatus for how those are detected).
#
# For each such game, #plan picks one action:
#
#   * :update_id       -> the item redirects to another item that no other game
#                         uses: point the game at the target.
#   * :duplicate       -> the item redirects to an item another game already
#                         uses. Both games are the same game, so they need
#                         merging by hand; nothing is changed.
#   * :blocklisted     -> the item redirects to a blocklisted item. Nothing is
#                         changed.
#   * :delete          -> the item was deleted and the game has no owners and
#                         no favorites: delete the game.
#   * :keep            -> the item was deleted but people own or favorited the
#                         game, so it stays. Nothing is changed.
#
# Planning only reads. #apply! carries out a planned :update_id or :delete,
# re-checking owners and favorites inside a transaction first so a game
# someone added in the meantime is never deleted.
class WikidataStaleGameCleanup
  # Actions that change data when applied.
  WRITE_ACTIONS = %i[update_id delete].freeze

  Result = Struct.new(
    :action,
    :game_id,
    :game_name,
    :wikidata_id,
    :new_wikidata_id,
    :other_game_id,
    :owners,
    :favorites,
    :error,
    keyword_init: true
  )

  # @param [ActiveRecord::Relation] games the games to check; games without a
  #   Wikidata ID are skipped.
  # @param [WikidataItemStatus] item_status
  def initialize(games: Game.all, item_status: WikidataItemStatus.new)
    @games = games.where.not(wikidata_id: nil)
    @item_status = item_status
  end

  # The number of games that will be checked.
  delegate :count, to: :@games

  # Check every game against Wikidata and decide what to do with the stale
  # ones. Read-only.
  #
  # @param [Proc] on_chunk see WikidataItemStatus#stale
  # @return [Array<Result>] one per game with a deleted or redirected item
  def plan(on_chunk: nil)
    statuses = @item_status.stale(@games.pluck(:wikidata_id), on_chunk: on_chunk)
    return [] if statuses.empty?

    games = @games.where(wikidata_id: statuses.keys).order(:id).to_a
    favorite_counts = FavoriteGame.where(game_id: games.map(&:id)).group(:game_id).count
    owner_counts = GamePurchase.where(game_id: games.map(&:id)).group(:game_id).count

    targets = statuses.values.filter_map(&:redirect_target)
    games_by_target = Game.where(wikidata_id: targets).pluck(:wikidata_id, :id).to_h
    blocklisted = WikidataBlocklist.where(wikidata_id: targets).pluck(:wikidata_id).to_set

    games.map do |game|
      status = statuses[game.wikidata_id]
      result = Result.new(
        game_id: game.id,
        game_name: game.name,
        wikidata_id: game.wikidata_id,
        owners: owner_counts.fetch(game.id, 0),
        favorites: favorite_counts.fetch(game.id, 0)
      )

      if status.state == :redirected
        plan_redirect(result, status.redirect_target, games_by_target, blocklisted)
      else
        result.action = result.owners.zero? && result.favorites.zero? ? :delete : :keep
      end

      result
    end
  end

  # Carry out a planned :update_id or :delete. Any other action is a no-op.
  #
  # On failure, the result's action becomes :error with the reason in
  # `error`, and a :delete whose game gained an owner or favorite since
  # planning becomes :keep.
  #
  # @param [Result] result
  # @return [Result] the same result, updated
  def apply!(result)
    case result.action
    when :update_id then apply_update_id(result)
    when :delete then apply_delete(result)
    end

    result
  rescue ActiveRecord::ActiveRecordError => e
    result.action = :error
    result.error = e.message
    result
  end

  private

  def plan_redirect(result, target, games_by_target, blocklisted)
    result.new_wikidata_id = target

    if blocklisted.include?(target)
      result.action = :blocklisted
    elsif (other_game_id = games_by_target[target])
      result.action = :duplicate
      result.other_game_id = other_game_id
    else
      result.action = :update_id
      # A second game redirecting to the same target is then a duplicate of
      # this one, rather than a uniqueness error at apply time.
      games_by_target[target] = result.game_id
    end
  end

  def apply_update_id(result)
    game = Game.find(result.game_id)
    return unless game.wikidata_id == result.wikidata_id

    game.update!(wikidata_id: result.new_wikidata_id)
  end

  def apply_delete(result)
    Game.transaction do
      game = Game.lock.find_by(id: result.game_id)
      next if game.nil? || game.wikidata_id != result.wikidata_id

      owners = game.game_purchases.count
      favorites = game.favorites.count
      if owners.positive? || favorites.positive?
        result.action = :keep
        result.owners = owners
        result.favorites = favorites
        next
      end

      game.destroy!
    end
  end
end
