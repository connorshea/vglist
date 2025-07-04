module Resolvers
  class GamePurchaseResolver < Resolvers::BaseResolver
    type Types::GamePurchaseType, null: true

    description "Find a game purchase by ID."

    argument :id, ID, required: true

    def resolve(id:)
      GamePurchase.find(id)
    end
  end
end
