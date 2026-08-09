# frozen_string_literal: true

module Types
  class LibraryStatusCountType < Types::BaseObject
    description "The number of games in a user's library that have a given completion status."

    field :status, Enums::GamePurchaseCompletionStatusType, null: false, description: "The completion status being counted."
    field :count, Integer, null: false, description: "The number of games in the library with this completion status."
  end
end
