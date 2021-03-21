# typed: strict
module Types
  class MutationType < Types::BaseObject
    description "Mutations are GraphQL requests that can be used to create, update, or delete records on vglist."

    field :favorite_game, mutation: Mutations::Games::FavoriteGame
    field :unfavorite_game, mutation: Mutations::Games::UnfavoriteGame
    field :remove_game_cover, mutation: Mutations::Games::RemoveGameCover

    field :follow_user, mutation: Mutations::Users::FollowUser
    field :unfollow_user, mutation: Mutations::Users::UnfollowUser
    field :ban_user, mutation: Mutations::Users::BanUser
    field :unban_user, mutation: Mutations::Users::UnbanUser

    field :add_game_to_library, mutation: Mutations::GamePurchases::AddGameToLibrary
    field :update_game_in_library, mutation: Mutations::GamePurchases::UpdateGameInLibrary
    field :remove_game_from_library, mutation: Mutations::GamePurchases::RemoveGameFromLibrary

    field :delete_event, mutation: Mutations::DeleteEvent

    # Admin
    field :add_to_wikidata_blocklist, mutation: Mutations::Admin::AddToWikidataBlocklist
    field :remove_from_wikidata_blocklist, mutation: Mutations::Admin::RemoveFromWikidataBlocklist
  end
end
