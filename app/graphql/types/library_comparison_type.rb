# frozen_string_literal: true

module Types
  # The object is a LibraryComparison.
  class LibraryComparisonType < Types::BaseObject
    description "A comparison of two users' game libraries: the games they both own, the games only one of them owns, and how their ratings differ."

    field :user_a, UserType, null: false, description: "The first user in the comparison."
    field :user_b, UserType, null: false, description: "The second user in the comparison."
    field :in_common_count, Integer, null: false, description: "The number of games both users own."
    field :only_a_count, Integer, null: false, description: "The number of games only the first user owns."
    field :only_b_count, Integer, null: false, description: "The number of games only the second user owns."
    field :both_rated_count, Integer, null: false, description: "The number of games both users own and have both rated."
    field :average_rating_gap, Float, null: true, description: "The average difference between the two users' ratings, out of 100 and rounded to one decimal place, across the games they have both rated. `null` if there are no such games."

    field :in_common, LibraryComparisonEntryType.connection_type, null: false, description: "The games both users own." do
      argument :sort_by, Enums::LibraryComparisonSortType, required: false, description: "How to sort the games. Defaults to `RATING_GAP`."
      argument :search, String, required: false, description: "Only include games whose name contains this text."
      argument :both_rated, Boolean, required: false, description: "Only include games both users have rated."
    end

    field :only_a, GamePurchaseType.connection_type, null: false, description: "The first user's library entries for the games the second user doesn't own." do
      argument :sort_by, Enums::GamePurchaseSortType, required: false, description: "How to sort the games. Defaults to `HIGHEST_RATING`."
      argument :search, String, required: false, description: "Only include games whose name contains this text."
    end

    field :only_b, GamePurchaseType.connection_type, null: false, description: "The second user's library entries for the games the first user doesn't own." do
      argument :sort_by, Enums::GamePurchaseSortType, required: false, description: "How to sort the games. Defaults to `HIGHEST_RATING`."
      argument :search, String, required: false, description: "Only include games whose name contains this text."
    end

    def in_common(sort_by: nil, search: nil, both_rated: false)
      @object.in_common(sort_by: sort_by, search: search, both_rated: both_rated)
             .includes(game: [:developers, AttachmentPreloads::COVER])
    end

    def only_a(sort_by: nil, search: nil)
      only_list(@object.only_a, sort_by: sort_by, search: search)
    end

    def only_b(sort_by: nil, search: nil)
      only_list(@object.only_b, sort_by: sort_by, search: search)
    end

    private

    def only_list(purchases, sort_by:, search:)
      purchases = purchases.includes(game: AttachmentPreloads::COVER)
      purchases = purchases.with_game_name_matching(search) if search.present?
      purchases.public_send((sort_by || 'highest_rating').to_sym)
    end
  end
end
