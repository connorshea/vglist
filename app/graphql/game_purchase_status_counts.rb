# frozen_string_literal: true

# Counts the games in a library by completion status in one grouped query, for
# a response that asks for several `User.gamePurchases` connections that differ
# only in their completion status, like the library page's shelves.
#
# `UserType#game_purchases` marks such a connection's relation with
# `GamePurchaseStatusCounts.extension(status)`, and `BaseConnectionObject`
# calls `batched_total_count` for its `totalCount`. The first shelf to be
# counted runs `GROUP BY completion_status` over the library with the shelves'
# shared filters, and every other shelf reads its count from that result.
#
# Without this, the library page's nine shelves run nine COUNT queries.
class GamePurchaseStatusCounts
  # @param status [String, nil] The completion status the relation filters on,
  #   `nil` for the games with no completion status.
  # @return [Module] A relation extension (see `ActiveRecord::QueryMethods#extending`).
  def self.extension(status)
    Module.new do
      define_method(:batched_total_count) do |context|
        GamePurchaseStatusCounts.new(context, self).count_for(status)
      end
    end
  end

  # @param context [GraphQL::Query::Context, Hash]
  # @param relation [ActiveRecord::Relation<GamePurchase>]
  def initialize(context, relation)
    @cache = context[:game_purchase_status_counts] ||= {}
    # The shelves share every other filter, so the relation without its
    # completion status (and without what doesn't change the count) is the
    # same for all of them.
    @base = relation.unscope(where: :completion_status).except(:order, :includes, :preload, :eager_load)
  end

  # @param status [String, nil]
  # @return [Integer]
  def count_for(status)
    counts.fetch(status, 0)
  end

  private

  def counts
    @cache[@base.to_sql] ||= @base.group(:completion_status).count.transform_keys do |status|
      status.is_a?(Integer) ? GamePurchase.completion_statuses.key(status) : status
    end
  end
end
