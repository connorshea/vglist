# typed: strict
module Types
  class QueryType < Types::BaseObject
    extend T::Sig

    description "Queries are GraphQL requests that can be used to request data from vglist's database."

    field :game, resolver: Resolvers::GameResolvers::GameResolver
    field :games, resolver: Resolvers::GameResolvers::ListResolver
    field :game_search, resolver: Resolvers::GameResolvers::SearchResolver

    field :series, resolver: Resolvers::SeriesResolvers::SeriesResolver
    field :series_list, resolver: Resolvers::SeriesResolvers::ListResolver
    field :series_search, resolver: Resolvers::SeriesResolvers::SearchResolver

    field :company, resolver: Resolvers::CompanyResolvers::CompanyResolver
    field :companies, resolver: Resolvers::CompanyResolvers::ListResolver
    field :company_search, resolver: Resolvers::CompanyResolvers::SearchResolver

    field :platform, resolver: Resolvers::PlatformResolvers::PlatformResolver
    field :platforms, resolver: Resolvers::PlatformResolvers::ListResolver
    field :platform_search, resolver: Resolvers::PlatformResolvers::SearchResolver

    field :engine, resolver: Resolvers::EngineResolvers::EngineResolver
    field :engines, resolver: Resolvers::EngineResolvers::ListResolver
    field :engine_search, resolver: Resolvers::EngineResolvers::SearchResolver

    field :genre, resolver: Resolvers::GenreResolvers::GenreResolver
    field :genres, resolver: Resolvers::GenreResolvers::ListResolver
    field :genre_search, resolver: Resolvers::GenreResolvers::SearchResolver

    field :store, resolver: Resolvers::StoreResolvers::StoreResolver
    field :stores, resolver: Resolvers::StoreResolvers::ListResolver
    field :store_search, resolver: Resolvers::StoreResolvers::SearchResolver

    field :user, resolver: Resolvers::UserResolvers::UserResolver
    field :users, resolver: Resolvers::UserResolvers::ListResolver
    field :user_search, resolver: Resolvers::UserResolvers::SearchResolver
    field :current_user, resolver: Resolvers::UserResolvers::CurrentUserResolver

    field :game_purchase, resolver: Resolvers::GamePurchaseResolver

    field :activity, resolver: Resolvers::ActivityResolver

    field :site_statistics, resolver: Resolvers::SiteStatisticResolvers::ListResolver
    field :basic_site_statistics, resolver: Resolvers::SiteStatisticResolvers::BasicResolver
  end
end
