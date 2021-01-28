# typed: strict
module Resolvers
  class GamePurchaseResolver < Resolvers::BaseResolver
    type Types::GamePurchaseType, null: true

    description "Find a game purchase by ID."

    argument :id, ID, required: true

    sig { params(id: T.any(String, Integer)).returns(GamePurchase) }
    def resolve(id:)
      GamePurchase.find(id)
    end
  end
end
