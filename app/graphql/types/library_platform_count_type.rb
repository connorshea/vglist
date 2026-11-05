# frozen_string_literal: true

module Types
  class LibraryPlatformCountType < Types::BaseObject
    description "The number of games in a user's library that the user owns on a given platform."

    field :platform, PlatformType, null: false, description: "The platform being counted."
    field :count, Integer, null: false, description: "The number of games in the library that the user owns on this platform."
  end
end
