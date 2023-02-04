# typed: strict
module Types
  class MutationType < Types::BaseObject
    description "Mutations are GraphQL requests that can be used to create, update, or delete records on vglist."

    # Game mutations
    field :create_game, mutation: Mutations::Games::CreateGame
    field :update_game, mutation: Mutations::Games::UpdateGame
    field :delete_game, mutation: Mutations::Games::DeleteGame
    field :favorite_game, mutation: Mutations::Games::FavoriteGame
    field :unfavorite_game, mutation: Mutations::Games::UnfavoriteGame
    field :remove_game_cover, mutation: Mutations::Games::RemoveGameCover

    # User mutations
    field :follow_user, mutation: Mutations::Users::FollowUser
    field :unfollow_user, mutation: Mutations::Users::UnfollowUser
    field :import_steam_library, mutation: Mutations::Users::ImportSteamLibrary
    field :connect_steam, mutation: Mutations::Users::ConnectSteam
    field :disconnect_steam, mutation: Mutations::Users::DisconnectSteam
    field :ban_user, mutation: Mutations::Users::BanUser
    field :unban_user, mutation: Mutations::Users::UnbanUser
    field :update_user_role, mutation: Mutations::Users::UpdateUserRole
    field :remove_user_avatar, mutation: Mutations::Users::RemoveUserAvatar
    field :reset_user_library, mutation: Mutations::Users::ResetUserLibrary
    field :delete_user, mutation: Mutations::Users::DeleteUser

    # GamePurchase mutations
    field :add_game_to_library, mutation: Mutations::GamePurchases::AddGameToLibrary
    field :update_game_in_library, mutation: Mutations::GamePurchases::UpdateGameInLibrary
    field :remove_game_from_library, mutation: Mutations::GamePurchases::RemoveGameFromLibrary

    # Company mutations
    field :create_company, mutation: Mutations::Companies::CreateCompany
    field :update_company, mutation: Mutations::Companies::UpdateCompany
    field :delete_company, mutation: Mutations::Companies::DeleteCompany

    # Engine mutations
    field :create_engine, mutation: Mutations::Engines::CreateEngine
    field :update_engine, mutation: Mutations::Engines::UpdateEngine
    field :delete_engine, mutation: Mutations::Engines::DeleteEngine

    # Genre mutations
    field :create_genre, mutation: Mutations::Genres::CreateGenre
    field :update_genre, mutation: Mutations::Genres::UpdateGenre
    field :delete_genre, mutation: Mutations::Genres::DeleteGenre

    # Platform mutations
    field :create_platform, mutation: Mutations::Platforms::CreatePlatform
    field :update_platform, mutation: Mutations::Platforms::UpdatePlatform
    field :delete_platform, mutation: Mutations::Platforms::DeletePlatform

    # Series mutations
    field :create_series, mutation: Mutations::Series::CreateSeries
    field :update_series, mutation: Mutations::Series::UpdateSeries
    field :delete_series, mutation: Mutations::Series::DeleteSeries

    # Store mutations
    field :create_store, mutation: Mutations::Stores::CreateStore
    field :update_store, mutation: Mutations::Stores::UpdateStore
    field :delete_store, mutation: Mutations::Stores::DeleteStore

    # Event mutations
    field :delete_event, mutation: Mutations::DeleteEvent

    # Admin dashboard mutations
    field :add_to_steam_blocklist, mutation: Mutations::Admin::AddToSteamBlocklist
    field :remove_from_steam_blocklist, mutation: Mutations::Admin::RemoveFromSteamBlocklist
    field :add_to_wikidata_blocklist, mutation: Mutations::Admin::AddToWikidataBlocklist
    field :remove_from_wikidata_blocklist, mutation: Mutations::Admin::RemoveFromWikidataBlocklist
    field :remove_from_unmatched_games, mutation: Mutations::Admin::RemoveFromUnmatchedGames
    field :merge_games, mutation: Mutations::Admin::MergeGames
  end
end
