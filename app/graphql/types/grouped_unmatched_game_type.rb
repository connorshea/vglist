# typed: strict
module Types
  class GroupedUnmatchedGameType < Types::BaseObject
    description "This represents a game that was imported from a third party service by a user, but which couldn't be matched to a game in the vglist database."

    field :external_service_name, Enums::UnmatchedGameExternalServiceType, null: false, description: "The external service the game was imported from."
    field :external_service_id, String, null: false, description: "The ID of the game on the external service."
    field :name, String, null: false, description: "The name of the game."
    field :count, Integer, null: false, description: "The number of distinct users that have attempted to import this game."
  end
end
