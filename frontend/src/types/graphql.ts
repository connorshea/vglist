/** Internal type. DO NOT USE DIRECTLY. */
type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** Internal type. DO NOT USE DIRECTLY. */
export type Incremental<T> = T | { [P in keyof T]?: P extends " $fragmentName" | "__typename" ? T[P] : never };
/** Options for filtering events in the activity feed. */
export type ActivityFeed =
  /** Events from the current user and anyone they follow. */
  | "FOLLOWING"
  /** Events from everyone. */
  | "GLOBAL";

/** Category types for events in the Activity Feed. */
export type EventCategory =
  /** Event for a user adding a game to their library. */
  | "ADD_TO_LIBRARY"
  /** Event for a user updating the completion status of a game. */
  | "CHANGE_COMPLETION_STATUS"
  /** Event for a user favoriting a game. */
  | "FAVORITE_GAME"
  /** Event for a user following another user. */
  | "FOLLOWING"
  /** Event for user creation. */
  | "NEW_USER";

/** Completion Status options for game purchases (games in a user's library). */
export type GamePurchaseCompletionStatus =
  /** The game has been completed. */
  | "COMPLETED"
  /** The game was dropped without being completed. */
  | "DROPPED"
  /** The game is 100% complete, e.g. with all achievements unlocked. */
  | "FULLY_COMPLETED"
  /** The game is currently being played. */
  | "IN_PROGRESS"
  /** The game cannot be completed. */
  | "NOT_APPLICABLE"
  /** The game is incomplete and not being played, but the user intends to come back to play it again later. */
  | "PAUSED"
  /** The game is unplayed. */
  | "UNPLAYED";

/** The types of records that can be returned as a `SearchResult`. */
export type SearchableEnum =
  /** Self-explanatory. */
  | "COMPANY"
  /** Self-explanatory. */
  | "ENGINE"
  /** Self-explanatory. */
  | "GAME"
  /** Self-explanatory. */
  | "GENRE"
  /** Self-explanatory. */
  | "PLATFORM"
  /** Self-explanatory. */
  | "SERIES"
  /** Self-explanatory. */
  | "USER";

/** External services that an Unmatched Game can come from, currently only Steam. */
export type UnmatchedGameExternalService =
  /** Imported from the Steam store. */
  "STEAM";

/** An enum describing the privacy level of a given user. Most users will be `PUBLIC_ACCOUNT`. */
export type UserPrivacy =
  /** User has a private profile. */
  | "PRIVATE_ACCOUNT"
  /** User has a publicly-visible profile. */
  | "PUBLIC_ACCOUNT";

/** Roles that a user can have, these define permissions levels. Most users will be `MEMBER`. */
export type UserRole =
  /** User is an admin and has the highest permissions. */
  | "ADMIN"
  /** User is a regular user. */
  | "MEMBER"
  /** User has some heightened permissions. */
  | "MODERATOR";

/** Options for sorting users. */
export type UserSort =
  /** Sorted by the number of users following the given user. */
  | "MOST_FOLLOWERS"
  /** Sorted by the number of games in the given user's library. */
  | "MOST_GAMES";

export type AddToSteamBlocklistMutationVariables = Exact<{
  name: string;
  steamAppId: number;
}>;

export interface AddToSteamBlocklistMutation {
  addToSteamBlocklist: { steamBlocklistEntry: { id: string; name: string; steamAppId: number } | null } | null;
}

export type RemoveFromSteamBlocklistMutationVariables = Exact<{
  steamBlocklistEntryId: string;
}>;

export interface RemoveFromSteamBlocklistMutation {
  removeFromSteamBlocklist: { deleted: boolean } | null;
}

export type AddToWikidataBlocklistMutationVariables = Exact<{
  name: string;
  wikidataId: number;
}>;

export interface AddToWikidataBlocklistMutation {
  addToWikidataBlocklist: { wikidataBlocklistEntry: { id: string; name: string; wikidataId: number } | null } | null;
}

export type RemoveFromWikidataBlocklistMutationVariables = Exact<{
  wikidataBlocklistEntryId: string;
}>;

export interface RemoveFromWikidataBlocklistMutation {
  removeFromWikidataBlocklist: { deleted: boolean } | null;
}

export type RemoveFromUnmatchedGamesMutationVariables = Exact<{
  externalServiceId: string;
  externalServiceName: UnmatchedGameExternalService;
}>;

export interface RemoveFromUnmatchedGamesMutation {
  removeFromUnmatchedGames: { deleted: boolean } | null;
}

export type MergeGamesMutationVariables = Exact<{
  gameToKeepId: string;
  gameToMergeId: string;
}>;

export interface MergeGamesMutation {
  mergeGames: { game: { id: string; name: string } } | null;
}

export type SignInMutationVariables = Exact<{
  email: string;
  password: string;
}>;

export interface SignInMutation {
  signIn: {
    token: string | null;
    userId: string | null;
    username: string | null;
    slug: string | null;
    role: string | null;
    errors: Array<string>;
  } | null;
}

export type SignUpMutationVariables = Exact<{
  username: string;
  email: string;
  password: string;
  passwordConfirmation: string;
}>;

export interface SignUpMutation {
  signUp: { message: string | null; errors: Array<string> } | null;
}

export type RequestPasswordResetMutationVariables = Exact<{
  email: string;
}>;

export interface RequestPasswordResetMutation {
  requestPasswordReset: { message: string } | null;
}

export type DeleteEventMutationVariables = Exact<{
  eventId: string;
}>;

export interface DeleteEventMutation {
  deleteEvent: { deleted: boolean } | null;
}

export type AddGameToLibraryMutationVariables = Exact<{
  gameId: string;
  completionStatus?: GamePurchaseCompletionStatus | null | undefined;
  rating?: number | null | undefined;
  hoursPlayed?: number | null | undefined;
  comments?: string | null | undefined;
  startDate?: string | null | undefined;
  completionDate?: string | null | undefined;
  platforms?: Array<string | null | undefined> | string | null | undefined;
  stores?: Array<string | null | undefined> | string | null | undefined;
}>;

export interface AddGameToLibraryMutation {
  addGameToLibrary: {
    gamePurchase: {
      id: string;
      completionStatus: GamePurchaseCompletionStatus | null;
      rating: number | null;
      hoursPlayed: number | null;
      comments: string | null;
      game: { id: string; name: string };
    } | null;
  } | null;
}

export type UpdateGameInLibraryMutationVariables = Exact<{
  gamePurchaseId: string;
  completionStatus?: GamePurchaseCompletionStatus | null | undefined;
  rating?: number | null | undefined;
  hoursPlayed?: number | null | undefined;
  comments?: string | null | undefined;
  startDate?: string | null | undefined;
  completionDate?: string | null | undefined;
  replayCount?: number | null | undefined;
  platforms?: Array<string | null | undefined> | string | null | undefined;
  stores?: Array<string | null | undefined> | string | null | undefined;
}>;

export interface UpdateGameInLibraryMutation {
  updateGameInLibrary: {
    gamePurchase: {
      id: string;
      completionStatus: GamePurchaseCompletionStatus | null;
      rating: number | null;
      hoursPlayed: number | null;
      comments: string | null;
    } | null;
  } | null;
}

export type RemoveGameFromLibraryMutationVariables = Exact<{
  gamePurchaseId: string;
}>;

export interface RemoveGameFromLibraryMutation {
  removeGameFromLibrary: { game: { id: string } | null } | null;
}

export type FavoriteGameMutationVariables = Exact<{
  gameId: string;
}>;

export interface FavoriteGameMutation {
  favoriteGame: { game: { id: string; name: string } | null } | null;
}

export type UnfavoriteGameMutationVariables = Exact<{
  gameId: string;
}>;

export interface UnfavoriteGameMutation {
  unfavoriteGame: { game: { id: string; name: string } | null } | null;
}

export type DeleteGameMutationVariables = Exact<{
  gameId: string;
}>;

export interface DeleteGameMutation {
  deleteGame: { deleted: boolean | null } | null;
}

export type RemoveGameCoverMutationVariables = Exact<{
  gameId: string;
}>;

export interface RemoveGameCoverMutation {
  removeGameCover: { game: { id: string } } | null;
}

export type CreateGameMutationVariables = Exact<{
  name: string;
  releaseDate?: string | null | undefined;
  wikidataId?: string | null | undefined;
  seriesId?: string | null | undefined;
  platformIds?: Array<string> | string | null | undefined;
  developerIds?: Array<string> | string | null | undefined;
  publisherIds?: Array<string> | string | null | undefined;
  genreIds?: Array<string> | string | null | undefined;
  engineIds?: Array<string> | string | null | undefined;
  pcgamingwikiId?: string | null | undefined;
  mobygamesId?: number | null | undefined;
  giantbombId?: string | null | undefined;
  epicGamesStoreId?: string | null | undefined;
  gogId?: string | null | undefined;
  igdbId?: string | null | undefined;
  steamAppIds?: Array<number> | number | null | undefined;
}>;

export interface CreateGameMutation {
  createGame: { game: { id: string; name: string } | null } | null;
}

export type UpdateGameMutationVariables = Exact<{
  gameId: string;
  name?: string | null | undefined;
  releaseDate?: string | null | undefined;
  wikidataId?: string | null | undefined;
  seriesId?: string | null | undefined;
  platformIds?: Array<string> | string | null | undefined;
  developerIds?: Array<string> | string | null | undefined;
  publisherIds?: Array<string> | string | null | undefined;
  genreIds?: Array<string> | string | null | undefined;
  engineIds?: Array<string> | string | null | undefined;
  pcgamingwikiId?: string | null | undefined;
  mobygamesId?: number | null | undefined;
  giantbombId?: string | null | undefined;
  epicGamesStoreId?: string | null | undefined;
  gogId?: string | null | undefined;
  igdbId?: string | null | undefined;
  steamAppIds?: Array<number> | number | null | undefined;
}>;

export interface UpdateGameMutation {
  updateGame: { game: { id: string; name: string } } | null;
}

export type UpdateUserMutationVariables = Exact<{
  bio?: string | null | undefined;
  privacy?: UserPrivacy | null | undefined;
  hideDaysPlayed?: boolean | null | undefined;
}>;

export interface UpdateUserMutation {
  updateUser: {
    errors: Array<string>;
    user: { id: string; bio: string | null; privacy: UserPrivacy; hideDaysPlayed: boolean } | null;
  } | null;
}

export type ResetApiTokenMutationVariables = Exact<{ [key: string]: never }>;

export interface ResetApiTokenMutation {
  resetApiToken: { apiToken: string | null; errors: Array<string> } | null;
}

export type ExportLibraryMutationVariables = Exact<{ [key: string]: never }>;

export interface ExportLibraryMutation {
  exportLibrary: { libraryJson: string | null; errors: Array<string> } | null;
}

export type DeleteUserMutationVariables = Exact<{
  userId: string;
}>;

export interface DeleteUserMutation {
  deleteUser: { deleted: boolean } | null;
}

export type ResetUserLibraryMutationVariables = Exact<{
  userId: string;
}>;

export interface ResetUserLibraryMutation {
  resetUserLibrary: { deleted: boolean } | null;
}

export type UpdateEmailMutationVariables = Exact<{
  newEmail: string;
  currentPassword: string;
}>;

export interface UpdateEmailMutation {
  updateEmail: { errors: Array<string>; user: { id: string } | null } | null;
}

export type UpdatePasswordMutationVariables = Exact<{
  currentPassword: string;
  newPassword: string;
  newPasswordConfirmation: string;
}>;

export interface UpdatePasswordMutation {
  updatePassword: { errors: Array<string>; user: { id: string } | null } | null;
}

export type FollowUserMutationVariables = Exact<{
  userId: string;
}>;

export interface FollowUserMutation {
  followUser: { user: { id: string; username: string } | null } | null;
}

export type UnfollowUserMutationVariables = Exact<{
  userId: string;
}>;

export interface UnfollowUserMutation {
  unfollowUser: { user: { id: string; username: string } | null } | null;
}

export type BanUserMutationVariables = Exact<{
  userId: string;
}>;

export interface BanUserMutation {
  banUser: { user: { id: string; banned: boolean; role: UserRole } | null } | null;
}

export type UnbanUserMutationVariables = Exact<{
  userId: string;
}>;

export interface UnbanUserMutation {
  unbanUser: { user: { id: string; banned: boolean } | null } | null;
}

export type UpdateUserRoleMutationVariables = Exact<{
  userId: string;
  role: UserRole;
}>;

export interface UpdateUserRoleMutation {
  updateUserRole: { user: { id: string; role: UserRole } | null } | null;
}

export type RemoveUserAvatarMutationVariables = Exact<{
  userId: string;
}>;

export interface RemoveUserAvatarMutation {
  removeUserAvatar: { user: { id: string; avatarUrl: string | null } } | null;
}

export type GetLiveStatisticsQueryVariables = Exact<{ [key: string]: never }>;

export interface GetLiveStatisticsQuery {
  liveStatistics: {
    users: number;
    games: number;
    platforms: number;
    series: number;
    engines: number;
    companies: number;
    genres: number;
    stores: number;
    events: number;
    gamePurchases: number;
    relationships: number;
    bannedUsers: number;
    gamesWithCovers: number;
    gamesWithReleaseDates: number;
    mobygamesIds: number;
    pcgamingwikiIds: number;
    wikidataIds: number;
    giantbombIds: number;
    steamAppIds: number;
    epicGamesStoreIds: number;
    gogIds: number;
    igdbIds: number | null;
  };
}

export type GetSteamBlocklistQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetSteamBlocklistQuery {
  steamBlocklist: {
    nodes: Array<{
      id: string;
      name: string;
      steamAppId: number;
      createdAt: string;
      user: { id: string; username: string; slug: string } | null;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetWikidataBlocklistQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetWikidataBlocklistQuery {
  wikidataBlocklist: {
    nodes: Array<{
      id: string;
      name: string;
      wikidataId: number;
      createdAt: string;
      user: { id: string; username: string; slug: string } | null;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetUnmatchedGamesQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetUnmatchedGamesQuery {
  groupedUnmatchedGames: {
    nodes: Array<{
      externalServiceName: UnmatchedGameExternalService;
      externalServiceId: string;
      name: string;
      count: number;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GameFieldsFragment = {
  id: string;
  name: string;
  releaseDate: string | null;
  avgRating: number | null;
  coverUrl: string | null;
  developers: { nodes: Array<{ id: string; name: string }> };
  publishers: { nodes: Array<{ id: string; name: string }> };
  platforms: { nodes: Array<{ id: string; name: string }> };
  genres: { nodes: Array<{ id: string; name: string }> };
  engines: { nodes: Array<{ id: string; name: string }> };
  series: { id: string; name: string } | null;
};

export type GetGameQueryVariables = Exact<{
  id: string;
}>;

export interface GetGameQuery {
  game: {
    isFavorited: boolean | null;
    isInLibrary: boolean | null;
    gamePurchaseId: string | null;
    wikidataId: number | null;
    steamAppIds: Array<number>;
    pcgamingwikiId: string | null;
    mobygamesId: number | null;
    giantbombId: string | null;
    epicGamesStoreId: string | null;
    gogId: string | null;
    igdbId: string | null;
    id: string;
    name: string;
    releaseDate: string | null;
    avgRating: number | null;
    coverUrl: string | null;
    owners: {
      totalCount: number;
      nodes: Array<{ id: string; slug: string; username: string; avatarUrl: string | null }>;
    };
    favoriters: {
      totalCount: number;
      nodes: Array<{ id: string; slug: string; username: string; avatarUrl: string | null }>;
    };
    developers: { nodes: Array<{ id: string; name: string }> };
    publishers: { nodes: Array<{ id: string; name: string }> };
    platforms: { nodes: Array<{ id: string; name: string }> };
    genres: { nodes: Array<{ id: string; name: string }> };
    engines: { nodes: Array<{ id: string; name: string }> };
    series: { id: string; name: string } | null;
  } | null;
}

export type GetGamesQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetGamesQuery {
  games: {
    nodes: Array<{
      id: string;
      name: string;
      releaseDate: string | null;
      coverUrl: string | null;
      developers: { nodes: Array<{ name: string }> };
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetRecentGamesQueryVariables = Exact<{
  first?: number | null | undefined;
}>;

export interface GetRecentGamesQuery {
  games: {
    nodes: Array<{
      id: string;
      name: string;
      coverUrl: string | null;
      platforms: { nodes: Array<{ id: string; name: string }> };
      developers: { nodes: Array<{ id: string; name: string }> };
    }>;
  } | null;
}

export type GetHeroCoversQueryVariables = Exact<{ [key: string]: never }>;

export interface GetHeroCoversQuery {
  games: { nodes: Array<{ coverUrl: string | null }> } | null;
}

export type GetGamePurchaseQueryVariables = Exact<{
  id: string;
}>;

export interface GetGamePurchaseQuery {
  gamePurchase: {
    id: string;
    completionStatus: GamePurchaseCompletionStatus | null;
    rating: number | null;
    hoursPlayed: number | null;
    comments: string | null;
    startDate: string | null;
    completionDate: string | null;
    platforms: { nodes: Array<{ id: string; name: string }> };
    stores: { nodes: Array<{ id: string; name: string }> };
  } | null;
}

export type GetPlatformsQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetPlatformsQuery {
  platforms: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetPlatformQueryVariables = Exact<{
  id: string;
}>;

export interface GetPlatformQuery {
  platform: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetCompaniesQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetCompaniesQuery {
  companies: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetCompanyQueryVariables = Exact<{
  id: string;
}>;

export interface GetCompanyQuery {
  company: {
    id: string;
    name: string;
    wikidataId: number | null;
    developedGames: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
    publishedGames: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetGenresQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetGenresQuery {
  genres: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetGenreQueryVariables = Exact<{
  id: string;
}>;

export interface GetGenreQuery {
  genre: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetEnginesQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetEnginesQuery {
  engines: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetEngineQueryVariables = Exact<{
  id: string;
}>;

export interface GetEngineQuery {
  engine: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetSeriesListQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetSeriesListQuery {
  seriesList: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetSeriesQueryVariables = Exact<{
  id: string;
}>;

export interface GetSeriesQuery {
  series: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetStoresQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetStoresQuery {
  stores: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetStoreQueryVariables = Exact<{
  id: string;
}>;

export interface GetStoreQuery {
  store: { id: string; name: string } | null;
}

type SearchResultFields_CompanySearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_EngineSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_GameSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_GenreSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_PlatformSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_SeriesSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

type SearchResultFields_UserSearchResult_Fragment = {
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

export type SearchResultFieldsFragment =
  | SearchResultFields_CompanySearchResult_Fragment
  | SearchResultFields_EngineSearchResult_Fragment
  | SearchResultFields_GameSearchResult_Fragment
  | SearchResultFields_GenreSearchResult_Fragment
  | SearchResultFields_PlatformSearchResult_Fragment
  | SearchResultFields_SeriesSearchResult_Fragment
  | SearchResultFields_UserSearchResult_Fragment;

export type GameSearchResultFieldsFragment = {
  coverUrl: string | null;
  developerName: string | null;
  releaseDate: string | null;
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

export type UserSearchResultFieldsFragment = {
  avatarUrl: string | null;
  slug: string;
  searchableId: string;
  searchableType: SearchableEnum;
  content: string;
};

export type GlobalSearchQueryVariables = Exact<{
  query: string;
}>;

export interface GlobalSearchQuery {
  globalSearch: {
    nodes: Array<
      | { searchableId: string; searchableType: SearchableEnum; content: string }
      | { searchableId: string; searchableType: SearchableEnum; content: string }
      | {
          searchableId: string;
          searchableType: SearchableEnum;
          content: string;
          coverUrl: string | null;
          developerName: string | null;
          releaseDate: string | null;
        }
      | { searchableId: string; searchableType: SearchableEnum; content: string }
      | { searchableId: string; searchableType: SearchableEnum; content: string }
      | { searchableId: string; searchableType: SearchableEnum; content: string }
      | {
          searchableId: string;
          searchableType: SearchableEnum;
          content: string;
          avatarUrl: string | null;
          slug: string;
        }
    >;
  };
}

export type GetActivityQueryVariables = Exact<{
  feedType?: ActivityFeed | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetActivityQuery {
  activity: {
    nodes: Array<{
      id: string;
      eventCategory: EventCategory;
      createdAt: string;
      user: { id: string; username: string; slug: string; avatarUrl: string | null };
      eventable:
        | { game: { id: string; name: string; coverUrl: string | null } }
        | {
            completionStatus: GamePurchaseCompletionStatus | null;
            rating: number | null;
            game: { id: string; name: string; coverUrl: string | null };
          }
        | { followed: { id: string; username: string; slug: string; avatarUrl: string | null } }
        | { id: string; username: string; slug: string; avatarUrl: string | null };
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetBasicSiteStatisticsQueryVariables = Exact<{ [key: string]: never }>;

export interface GetBasicSiteStatisticsQuery {
  basicSiteStatistics: {
    games: number;
    platforms: number;
    series: number;
    engines: number;
    companies: number;
    genres: number;
  };
}

export type GetUserQueryVariables = Exact<{
  slug: string;
}>;

export interface GetUserQuery {
  user: {
    id: string;
    username: string;
    bio: string | null;
    slug: string;
    role: UserRole;
    privacy: UserPrivacy;
    createdAt: string;
    banned: boolean;
    avatarUrl: string | null;
    isFollowed: boolean | null;
    hideDaysPlayed: boolean;
    gamePurchases: {
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
    followers: { totalCount: number };
    following: { totalCount: number };
    favoritedGames: { nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
  } | null;
}

export type GetUsersQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: UserSort | null | undefined;
}>;

export interface GetUsersQuery {
  users: {
    totalCount: number;
    nodes: Array<{
      id: string;
      username: string;
      slug: string;
      avatarUrl: string | null;
      role: UserRole;
      privacy: UserPrivacy;
      banned: boolean;
      createdAt: string;
      gamePurchases: { totalCount: number };
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetUserFollowersQueryVariables = Exact<{
  slug: string;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetUserFollowersQuery {
  user: {
    id: string;
    username: string;
    followers: {
      totalCount: number;
      nodes: Array<{ id: string; username: string; slug: string; avatarUrl: string | null }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetUserFollowingQueryVariables = Exact<{
  slug: string;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetUserFollowingQuery {
  user: {
    id: string;
    username: string;
    following: {
      totalCount: number;
      nodes: Array<{ id: string; username: string; slug: string; avatarUrl: string | null }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetUserActivityQueryVariables = Exact<{
  slug: string;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetUserActivityQuery {
  user: {
    id: string;
    username: string;
    slug: string;
    activity: {
      nodes: Array<{
        id: string;
        eventCategory: EventCategory;
        createdAt: string;
        user: { id: string; username: string; slug: string; avatarUrl: string | null };
        eventable:
          | { game: { id: string; name: string; coverUrl: string | null } }
          | {
              completionStatus: GamePurchaseCompletionStatus | null;
              rating: number | null;
              game: { id: string; name: string; coverUrl: string | null };
            }
          | { followed: { id: string; username: string; slug: string; avatarUrl: string | null } }
          | { id: string; username: string; slug: string; avatarUrl: string | null };
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetCurrentUserProfileQueryVariables = Exact<{ [key: string]: never }>;

export interface GetCurrentUserProfileQuery {
  currentUser: { id: string; bio: string | null; privacy: UserPrivacy; hideDaysPlayed: boolean } | null;
}
