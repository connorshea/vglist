# typed: strict
module Types
  class MutationType < Types::BaseObject
    field :favorite_game, mutation: Mutations::FavoriteGame
    field :unfavorite_game, mutation: Mutations::UnfavoriteGame

    field :follow_user, mutation: Mutations::FollowUser
    field :unfollow_user, mutation: Mutations::UnfollowUser

    field :add_game_to_library, mutation: Mutations::AddGameToLibrary
    field :remove_game_from_library, mutation: Mutations::RemoveGameFromLibrary
  end
end
