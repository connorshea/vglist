# frozen_string_literal: true

# Loads game purchases by ID, batched across every one requested in the
# response. Used for the second user's purchase in each row of a library
# comparison, which the comparison's own query only knows the ID of.
#
# GraphQL-Ruby resolves these only after the rest of the list has been visited
# (see `lazy_resolve` in VideoGameListSchema), so the first one to be resolved
# loads every purchase queued so far in one query. Without this, a page of 50
# rows would run 50 queries.
class LazyGamePurchase
  def initialize(context, game_purchase_id)
    @game_purchase_id = game_purchase_id
    @state = context[:lazy_game_purchases] ||= { pending: Set.new, loaded: {} }
    @state[:pending] << game_purchase_id unless @state[:loaded].key?(game_purchase_id)
  end

  # nil if the purchase was deleted after the comparison was queried, which
  # graphql-ruby reports as an error on that one row rather than failing the
  # whole request.
  #
  # @return [GamePurchase, nil]
  def value
    load_pending unless @state[:loaded].key?(@game_purchase_id)
    @state[:loaded][@game_purchase_id]
  end

  private

  def load_pending
    ids = @state[:pending].to_a
    found = GamePurchase.where(id: ids).index_by(&:id)
    ids.each { |id| @state[:loaded][id] = found[id] }
    @state[:pending].clear
  end
end
