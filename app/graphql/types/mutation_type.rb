# typed: strict
module Types
  class MutationType < Types::BaseObject
    description "Mutations are GraphQL requests that can be used to create, update, or delete records on vglist."

    field :favorite_game, mutation: Mutations::FavoriteGame
    field :unfavorite_game, mutation: Mutations::UnfavoriteGame

    field :follow_user, mutation: Mutations::FollowUser
    field :unfollow_user, mutation: Mutations::UnfollowUser

    field :add_game_to_library, mutation: Mutations::AddGameToLibrary
    field :update_game_in_library, mutation: Mutations::UpdateGameInLibrary
    field :remove_game_from_library, mutation: Mutations::RemoveGameFromLibrary

    field :delete_event, mutation: Mutations::DeleteEvent
  end
end
