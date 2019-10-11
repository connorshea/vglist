# typed: true
module Types
  class MutationType < Types::BaseObject
    field :favorite_game, mutation: Mutations::FavoriteGame
    field :unfavorite_game, mutation: Mutations::UnfavoriteGame

    field :follow_user, mutation: Mutations::FollowUser
    field :unfollow_user, mutation: Mutations::UnfollowUser
  end
end
