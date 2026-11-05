# frozen_string_literal: true

# Counts a game's public, unbanned owners, batched across every game in the
# response. Each `Game.ownerCount` field returns one of these instead of an
# Integer; GraphQL-Ruby resolves them only after the rest of the list has been
# visited (see `lazy_resolve` in VideoGameListSchema), so the first one to be
# resolved counts the owners of all the games queued so far in one query.
#
# Without this, a page of 36 game tiles runs 36 COUNT queries.
class LazyOwnerCount
  def initialize(context, game_id)
    @game_id = game_id
    @state = context[:lazy_owner_counts] ||= { pending: Set.new, loaded: {} }
    @state[:pending] << game_id unless @state[:loaded].key?(game_id)
  end

  # @return [Integer]
  def value
    load_pending unless @state[:loaded].key?(@game_id)
    @state[:loaded].fetch(@game_id)
  end

  private

  def load_pending
    game_ids = @state[:pending].to_a
    counts = GamePurchase.joins(:user)
                         .merge(User.public_and_unbanned)
                         .where(game_id: game_ids)
                         .group(:game_id)
                         .count
    game_ids.each { |id| @state[:loaded][id] = counts.fetch(id, 0) }
    @state[:pending].clear
  end
end
