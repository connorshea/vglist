# frozen_string_literal: true

module Types
  # The object is user A's GamePurchase, with `other_purchase_id` and
  # `rating_difference` selected onto it by `LibraryComparison#in_common`, so
  # `game` and `rating_difference` resolve straight from it.
  class LibraryComparisonEntryType < Types::BaseObject
    description "A game that both users in a library comparison own, with each user's library entry for it."

    field :game, GameType, null: false, description: "The game both users own."
    field :purchase_a, GamePurchaseType, null: false, description: "The first user's library entry for the game."
    field :purchase_b, GamePurchaseType, null: false, description: "The second user's library entry for the game."
    field :rating_difference, Integer, null: true, description: "The first user's rating minus the second user's: positive when the first user rated the game higher, negative when the second user did. `null` unless both users rated the game."

    def purchase_a
      @object
    end

    def purchase_b
      LazyGamePurchase.new(@context, @object.other_purchase_id)
    end
  end
end
