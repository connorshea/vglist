# frozen_string_literal: true

module Types
  class LibraryStoreCountType < Types::BaseObject
    description "The number of games in a user's library that the user owns from a given store."

    field :store, StoreType, null: false, description: "The store being counted."
    field :count, Integer, null: false, description: "The number of games in the library that the user owns from this store."
  end
end
