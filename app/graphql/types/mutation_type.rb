# typed: true
module Types
  class MutationType < Types::BaseObject
    field :favorite_game, mutation: Mutations::FavoriteGame
    field :unfavorite_game, mutation: Mutations::UnfavoriteGame
  end
end
