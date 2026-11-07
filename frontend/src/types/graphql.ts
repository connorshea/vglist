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

/** Options for sorting the games in a user's library. */
export type GamePurchaseSort =
  /** Sorted alphabetically by the name of the game. */
  | "GAME_NAME"
  /** Sorted with the user's highest-rated games first. Games the user hasn't rated are last. */
  | "HIGHEST_RATING"
  /** Sorted with the games the user has played the most hours of first. Games with no hours logged are last. */
  | "MOST_HOURS_PLAYED";

/** Options for sorting the reviews of a game. */
export type GameReviewSort =
  /** Sorted with the highest-rated reviews first. Reviews without a rating are last. */
  | "HIGHEST_RATING"
  /** Sorted with the lowest-rated reviews first. Reviews without a rating are last. */
  | "LOWEST_RATING"
  /** Sorted with the most recently updated reviews first. */
  | "RECENT";

/** Options for sorting games. */
export type GameSort =
  /** Sorted by the games that have the highest average rating. */
  | "HIGHEST_AVG_RATING"
  /** Sorted with most recently updated game records last. */
  | "LEAST_RECENTLY_UPDATED"
  /** Sorted by the games that have been favorited the most times. */
  | "MOST_FAVORITES"
  /** Sorted by the games that are in the most users' libraries. */
  | "MOST_OWNERS"
  /** Sorted with newest game records first. */
  | "NEWEST"
  /** Sorted with newest game records last. */
  | "OLDEST"
  /** Sorted with the games that were most recently released first. */
  | "RECENTLY_RELEASED"
  /** Sorted with most recently updated game records first. */
  | "RECENTLY_UPDATED";

/** Options for sorting the games two users have in common. */
export type LibraryComparisonSort =
  /** Sorted alphabetically by the name of the game. */
  | "GAME_NAME"
  /** Sorted with the games the two users disagree on most first. Games that either user hasn't rated are last. */
  | "RATING_GAP"
  /** Sorted with the first user's highest-rated games first. Games they haven't rated are last. */
  | "USER_A_RATING"
  /** Sorted with the second user's highest-rated games first. Games they haven't rated are last. */
  | "USER_B_RATING";

/** Options for sorting the games on a company, platform, engine, genre or series. */
export type ResourceGameSort =
  /** Sorted by the games with the highest average rating. Games without a rating come last. */
  | "HIGHEST_RATED"
  /** Sorted by the games that are in the most users' libraries. */
  | "MOST_OWNERS"
  /** Sorted alphabetically by name. */
  | "NAME"
  /** Sorted with the most recently released games first. Games without a release date come last. */
  | "NEWEST_RELEASE";

/** Options for sorting resources that games belong to, like genres and platforms. */
export type ResourceSort =
  /** Sorted by the number of games in the given resource, most first. */
  | "MOST_GAMES"
  /** Sorted alphabetically by name, ignoring case. */
  | "NAME"
  /** Sorted with the resources most recently added to vglist first. */
  | "RECENTLY_ADDED";

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

/** Options for sorting the list of series. */
export type SeriesSort =
  /** Sorted by the number of games in the series, most first. */
  | "MOST_GAMES"
  /** Sorted alphabetically by name, ignoring case. */
  | "NAME"
  /** Sorted with the series most recently added to vglist first. */
  | "RECENTLY_ADDED";

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
    avatarUrl: string | null;
    errors: Array<string>;
  } | null;
}

export type SignUpMutationVariables = Exact<{
  username: string;
  email: string;
  password: string;
  passwordConfirmation: string;
  turnstileToken?: string | null | undefined;
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
  replayCount?: number | null | undefined;
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
      replayCount: number;
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
      replayCount: number;
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

export type PasskeyAuthenticationOptionsMutationVariables = Exact<{ [key: string]: never }>;

export interface PasskeyAuthenticationOptionsMutation {
  passkeyAuthenticationOptions: { options: unknown } | null;
}

export type SignInWithPasskeyMutationVariables = Exact<{
  response: unknown;
}>;

export interface SignInWithPasskeyMutation {
  signInWithPasskey: {
    token: string | null;
    userId: string | null;
    username: string | null;
    slug: string | null;
    role: string | null;
    email: string | null;
    avatarUrl: string | null;
    errors: Array<string>;
  } | null;
}

export type PasskeyRegistrationOptionsMutationVariables = Exact<{
  currentPassword: string;
}>;

export interface PasskeyRegistrationOptionsMutation {
  passkeyRegistrationOptions: { options: unknown; errors: Array<string> } | null;
}

export type RegisterPasskeyMutationVariables = Exact<{
  response: unknown;
  nickname?: string | null | undefined;
}>;

export interface RegisterPasskeyMutation {
  registerPasskey: {
    errors: Array<string>;
    passkey: { id: string; nickname: string; backedUp: boolean; lastUsedAt: string | null; createdAt: string } | null;
  } | null;
}

export type RenamePasskeyMutationVariables = Exact<{
  id: string;
  nickname: string;
}>;

export interface RenamePasskeyMutation {
  renamePasskey: { errors: Array<string>; passkey: { id: string; nickname: string } | null } | null;
}

export type DeletePasskeyMutationVariables = Exact<{
  id: string;
}>;

export interface DeletePasskeyMutation {
  deletePasskey: { deleted: boolean } | null;
}

export type CreatePlatformMutationVariables = Exact<{
  name: string;
  wikidataId: string;
}>;

export interface CreatePlatformMutation {
  createPlatform: { platform: { id: string; name: string } | null } | null;
}

export type UpdatePlatformMutationVariables = Exact<{
  platformId: string;
  name?: string | null | undefined;
  wikidataId?: string | null | undefined;
}>;

export interface UpdatePlatformMutation {
  updatePlatform: { platform: { id: string; name: string } } | null;
}

export type DeletePlatformMutationVariables = Exact<{
  platformId: string;
}>;

export interface DeletePlatformMutation {
  deletePlatform: { deleted: boolean | null } | null;
}

export type CreateCompanyMutationVariables = Exact<{
  name: string;
  wikidataId: string;
}>;

export interface CreateCompanyMutation {
  createCompany: { company: { id: string; name: string } | null } | null;
}

export type UpdateCompanyMutationVariables = Exact<{
  companyId: string;
  name?: string | null | undefined;
  wikidataId?: string | null | undefined;
}>;

export interface UpdateCompanyMutation {
  updateCompany: { company: { id: string; name: string } } | null;
}

export type DeleteCompanyMutationVariables = Exact<{
  companyId: string;
}>;

export interface DeleteCompanyMutation {
  deleteCompany: { deleted: boolean | null } | null;
}

export type CreateEngineMutationVariables = Exact<{
  name: string;
  wikidataId: string;
}>;

export interface CreateEngineMutation {
  createEngine: { engine: { id: string; name: string } | null } | null;
}

export type UpdateEngineMutationVariables = Exact<{
  engineId: string;
  name?: string | null | undefined;
  wikidataId?: string | null | undefined;
}>;

export interface UpdateEngineMutation {
  updateEngine: { engine: { id: string; name: string } } | null;
}

export type DeleteEngineMutationVariables = Exact<{
  engineId: string;
}>;

export interface DeleteEngineMutation {
  deleteEngine: { deleted: boolean | null } | null;
}

export type CreateGenreMutationVariables = Exact<{
  name: string;
  wikidataId: string;
}>;

export interface CreateGenreMutation {
  createGenre: { genre: { id: string; name: string } | null } | null;
}

export type UpdateGenreMutationVariables = Exact<{
  genreId: string;
  name?: string | null | undefined;
  wikidataId?: string | null | undefined;
}>;

export interface UpdateGenreMutation {
  updateGenre: { genre: { id: string; name: string } } | null;
}

export type DeleteGenreMutationVariables = Exact<{
  genreId: string;
}>;

export interface DeleteGenreMutation {
  deleteGenre: { deleted: boolean | null } | null;
}

export type CreateSeriesMutationVariables = Exact<{
  name: string;
  wikidataId: string;
}>;

export interface CreateSeriesMutation {
  createSeries: { series: { id: string; name: string } | null } | null;
}

export type UpdateSeriesMutationVariables = Exact<{
  seriesId: string;
  name?: string | null | undefined;
  wikidataId?: string | null | undefined;
}>;

export interface UpdateSeriesMutation {
  updateSeries: { series: { id: string; name: string } } | null;
}

export type DeleteSeriesMutationVariables = Exact<{
  seriesId: string;
}>;

export interface DeleteSeriesMutation {
  deleteSeries: { deleted: boolean | null } | null;
}

export type CreateStoreMutationVariables = Exact<{
  name: string;
}>;

export interface CreateStoreMutation {
  createStore: { store: { id: string; name: string } | null } | null;
}

export type UpdateStoreMutationVariables = Exact<{
  storeId: string;
  name?: string | null | undefined;
}>;

export interface UpdateStoreMutation {
  updateStore: { store: { id: string; name: string } } | null;
}

export type DeleteStoreMutationVariables = Exact<{
  storeId: string;
}>;

export interface DeleteStoreMutation {
  deleteStore: { deleted: boolean | null } | null;
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

export type ConnectSteamMutationVariables = Exact<{
  userId: string;
  steamUsername: string;
}>;

export interface ConnectSteamMutation {
  connectSteam: { connected: boolean } | null;
}

export type DisconnectSteamMutationVariables = Exact<{
  userId: string;
}>;

export interface DisconnectSteamMutation {
  disconnectSteam: { disconnected: boolean } | null;
}

export type ImportSteamLibraryMutationVariables = Exact<{
  userId: string;
  updateHours?: boolean | null | undefined;
}>;

export interface ImportSteamLibraryMutation {
  importSteamLibrary: {
    addedGamesCount: number;
    updatedGamesCount: number;
    unmatchedCount: number;
    addedGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    updatedGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    unmatchedGames: Array<{ name: string; steamAppId: number }>;
  } | null;
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

export type GetSiteStatisticsQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetSiteStatisticsQuery {
  siteStatistics: {
    nodes: Array<{
      id: string;
      timestamp: string;
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
      gamesWithCovers: number;
      gamesWithReleaseDates: number;
      bannedUsers: number;
      unmatchedGames: number | null;
      mobygamesIds: number;
      pcgamingwikiIds: number;
      wikidataIds: number;
      giantbombIds: number;
      steamAppIds: number;
      epicGamesStoreIds: number;
      gogIds: number;
      igdbIds: number | null;
      companyVersions: number | null;
      gameVersions: number | null;
      genreVersions: number | null;
      engineVersions: number | null;
      platformVersions: number | null;
      seriesVersions: number | null;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type SearchGamesToMergeQueryVariables = Exact<{
  query: string;
}>;

export interface SearchGamesToMergeQuery {
  gameSearch: {
    nodes: Array<{ id: string; name: string; releaseDate: string | null; coverUrl: string | null; ownerCount: number }>;
  } | null;
}

export type ComparisonUserFieldsFragment = { id: string; username: string; slug: string; avatarUrl: string | null };

export type GetLibraryComparisonQueryVariables = Exact<{
  userASlug: string;
  userBSlug: string;
  shelfCount: number;
}>;

export interface GetLibraryComparisonQuery {
  libraryComparison: {
    inCommonCount: number;
    onlyACount: number;
    onlyBCount: number;
    bothRatedCount: number;
    averageRatingGap: number | null;
    userA: { id: string; username: string; slug: string; avatarUrl: string | null };
    userB: { id: string; username: string; slug: string; avatarUrl: string | null };
    onlyA: {
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    onlyB: {
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
  } | null;
}

export type GetComparisonInCommonQueryVariables = Exact<{
  userASlug: string;
  userBSlug: string;
  first: number;
  after?: string | null | undefined;
  sortBy?: LibraryComparisonSort | null | undefined;
  search?: string | null | undefined;
  bothRated?: boolean | null | undefined;
}>;

export interface GetComparisonInCommonQuery {
  libraryComparison: {
    inCommon: {
      totalCount: number;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
      nodes: Array<{
        ratingDifference: number | null;
        game: {
          id: string;
          name: string;
          coverUrl: string | null;
          developers: { nodes: Array<{ id: string; name: string }> };
        };
        purchaseA: { id: string; rating: number | null; completionStatus: GamePurchaseCompletionStatus | null };
        purchaseB: { id: string; rating: number | null; completionStatus: GamePurchaseCompletionStatus | null };
      }>;
    };
  } | null;
}

export type GetComparisonOnlyQueryVariables = Exact<{
  userASlug: string;
  userBSlug: string;
  sideA: boolean;
  first: number;
  after?: string | null | undefined;
  sortBy?: GamePurchaseSort | null | undefined;
  search?: string | null | undefined;
}>;

export interface GetComparisonOnlyQuery {
  libraryComparison: {
    onlyA?: {
      totalCount: number;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    onlyB?: {
      totalCount: number;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
  } | null;
}

export type ComparisonOnlyFieldsFragment = {
  totalCount: number;
  pageInfo: { hasNextPage: boolean; endCursor: string | null };
  nodes: Array<{
    id: string;
    hoursPlayed: number | null;
    completionStatus: GamePurchaseCompletionStatus | null;
    rating: number | null;
    game: { id: string; name: string; coverUrl: string | null };
  }>;
};

export type SearchUsersToCompareQueryVariables = Exact<{
  query: string;
}>;

export interface SearchUsersToCompareQuery {
  userSearch: {
    nodes: Array<{
      privacy: UserPrivacy;
      banned: boolean;
      id: string;
      username: string;
      slug: string;
      avatarUrl: string | null;
    }>;
  } | null;
}

export type GameTileFieldsFragment = {
  id: string;
  name: string;
  releaseDate: string | null;
  avgRating: number | null;
  coverUrl: string | null;
  isInLibrary: boolean | null;
  libraryCompletionStatus: GamePurchaseCompletionStatus | null;
  ownerCount: number;
};

export type GetGamesIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: GameSort | null | undefined;
  onPlatform?: string | null | undefined;
  byGenre?: string | null | undefined;
  byEngine?: string | null | undefined;
  fromYear?: number | null | undefined;
  toYear?: number | null | undefined;
  excludeLibrary?: boolean | null | undefined;
  withCount: boolean;
}>;

export interface GetGamesIndexQuery {
  games: {
    totalCount?: number;
    nodes: Array<{
      id: string;
      name: string;
      releaseDate: string | null;
      avgRating: number | null;
      coverUrl: string | null;
      isInLibrary: boolean | null;
      libraryCompletionStatus: GamePurchaseCompletionStatus | null;
      ownerCount: number;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetGamesIndexFiltersQueryVariables = Exact<{
  platformId: string;
  hasPlatform: boolean;
  genreId: string;
  hasGenre: boolean;
  engineId: string;
  hasEngine: boolean;
}>;

export interface GetGamesIndexFiltersQuery {
  basicSiteStatistics: { games: number };
  platforms: { nodes: Array<{ id: string; name: string }> } | null;
  genres: { nodes: Array<{ id: string; name: string }> } | null;
  platform?: { id: string; name: string } | null;
  genre?: { id: string; name: string } | null;
  engine?: { id: string; name: string } | null;
}

export type SearchPlatformsForFilterQueryVariables = Exact<{
  query: string;
}>;

export interface SearchPlatformsForFilterQuery {
  platformSearch: { nodes: Array<{ id: string; name: string }> } | null;
}

export type SearchGenresForFilterQueryVariables = Exact<{
  query: string;
}>;

export interface SearchGenresForFilterQuery {
  genreSearch: { nodes: Array<{ id: string; name: string }> } | null;
}

export type SearchEnginesForFilterQueryVariables = Exact<{
  query: string;
}>;

export interface SearchEnginesForFilterQuery {
  engineSearch: { nodes: Array<{ id: string; name: string }> } | null;
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
    ratingCount: number;
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
    moreFromSeries: { nodes: Array<{ id: string; name: string; releaseDate: string | null; coverUrl: string | null }> };
    developers: { nodes: Array<{ id: string; name: string }> };
    publishers: { nodes: Array<{ id: string; name: string }> };
    platforms: { nodes: Array<{ id: string; name: string }> };
    genres: { nodes: Array<{ id: string; name: string }> };
    engines: { nodes: Array<{ id: string; name: string }> };
    series: { id: string; name: string } | null;
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
    replayCount: number;
    comments: string | null;
    startDate: string | null;
    completionDate: string | null;
    platforms: { nodes: Array<{ id: string; name: string }> };
    stores: { nodes: Array<{ id: string; name: string }> };
  } | null;
}

export type GetGameReviewsQueryVariables = Exact<{
  id: string;
  sortBy?: GameReviewSort | null | undefined;
  first?: number | null | undefined;
}>;

export interface GetGameReviewsQuery {
  game: {
    id: string;
    reviews: {
      totalCount: number;
      nodes: Array<{
        id: string;
        comments: string | null;
        rating: number | null;
        hoursPlayed: number | null;
        replayCount: number;
        completionStatus: GamePurchaseCompletionStatus | null;
        updatedAt: string;
        user: { id: string; username: string; slug: string; avatarUrl: string | null };
        platforms: { nodes: Array<{ id: string; name: string }> };
      }>;
    };
  } | null;
}

export type GetGameActivityQueryVariables = Exact<{
  id: string;
  first?: number | null | undefined;
}>;

export interface GetGameActivityQuery {
  game: {
    id: string;
    activity: {
      nodes: Array<{
        id: string;
        eventCategory: EventCategory;
        createdAt: string;
        user: { id: string; username: string; slug: string; avatarUrl: string | null };
        completionStatusChange: { after: GamePurchaseCompletionStatus | null } | null;
        eventable: { id: string; completionStatus: GamePurchaseCompletionStatus | null } | Record<PropertyKey, never>;
      }>;
    };
  } | null;
}

export type GetLibraryPageQueryVariables = Exact<{
  slug: string;
}>;

export interface GetLibraryPageQuery {
  user: {
    id: string;
    hideDaysPlayed: boolean;
    libraryStatistics: {
      gamesCount: number;
      statusCounts: Array<{ status: GamePurchaseCompletionStatus; count: number }>;
      platformCounts: Array<{ count: number; platform: { id: string; name: string } }>;
      storeCounts: Array<{ count: number; store: { id: string; name: string } }>;
    };
  } | null;
}

export type LibraryGamePurchaseFieldsFragment = {
  id: string;
  hoursPlayed: number | null;
  completionStatus: GamePurchaseCompletionStatus | null;
  rating: number | null;
  game: { id: string; name: string; coverUrl: string | null };
};

export type LibraryPlayingPurchaseFieldsFragment = {
  startDate: string | null;
  id: string;
  hoursPlayed: number | null;
  completionStatus: GamePurchaseCompletionStatus | null;
  rating: number | null;
  platforms: { nodes: Array<{ id: string; name: string }> };
  stores: { nodes: Array<{ id: string; name: string }> };
  game: { id: string; name: string; coverUrl: string | null };
};

export type GetLibraryGamesQueryVariables = Exact<{
  slug: string;
  first?: number | null | undefined;
  after?: string | null | undefined;
  completionStatus?: GamePurchaseCompletionStatus | null | undefined;
  noCompletionStatus?: boolean | null | undefined;
  search?: string | null | undefined;
  sortBy?: GamePurchaseSort | null | undefined;
  platformIds?: Array<string> | string | null | undefined;
  storeIds?: Array<string> | string | null | undefined;
  minRating?: number | null | undefined;
  maxRating?: number | null | undefined;
}>;

export interface GetLibraryGamesQuery {
  user: {
    id: string;
    gamePurchases: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetLibraryShelvesQueryVariables = Exact<{
  slug: string;
  first: number;
  search?: string | null | undefined;
  sortBy?: GamePurchaseSort | null | undefined;
  platformIds?: Array<string> | string | null | undefined;
  storeIds?: Array<string> | string | null | undefined;
  minRating?: number | null | undefined;
  maxRating?: number | null | undefined;
}>;

export interface GetLibraryShelvesQuery {
  user: {
    id: string;
    inProgress: {
      totalCount: number;
      nodes: Array<{
        startDate: string | null;
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        platforms: { nodes: Array<{ id: string; name: string }> };
        stores: { nodes: Array<{ id: string; name: string }> };
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    paused: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    completed: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    fullyCompleted: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    unplayed: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    dropped: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    notApplicable: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    noStatus: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
  } | null;
}

export type LibraryShelfFieldsFragment = {
  totalCount: number;
  nodes: Array<{
    id: string;
    hoursPlayed: number | null;
    completionStatus: GamePurchaseCompletionStatus | null;
    rating: number | null;
    game: { id: string; name: string; coverUrl: string | null };
  }>;
};

export type ResourceGameFieldsFragment = {
  id: string;
  name: string;
  coverUrl: string | null;
  releaseDate: string | null;
  isInLibrary: boolean | null;
};

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
  sortBy?: ResourceGameSort | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetPlatformQuery {
  platform: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: {
      totalCount: number;
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetPlatformForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetPlatformForEditQuery {
  platform: { id: string; name: string; wikidataId: number | null } | null;
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

export type GetCompaniesIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: ResourceSort | null | undefined;
  nameContains?: string | null | undefined;
}>;

export interface GetCompaniesIndexQuery {
  companies: {
    totalCount: number;
    nodes: Array<{
      id: string;
      name: string;
      gamesCount: number;
      coverGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetCompanyQueryVariables = Exact<{
  id: string;
  sortBy?: ResourceGameSort | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
  developed?: boolean | null | undefined;
}>;

export interface GetCompanyQuery {
  company: {
    id: string;
    name: string;
    wikidataId: number | null;
    developedCount: { totalCount: number };
    publishedCount: { totalCount: number };
    developedGames?: {
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
    publishedGames?: {
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetCompanyForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetCompanyForEditQuery {
  company: { id: string; name: string; wikidataId: number | null } | null;
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
  sortBy?: ResourceGameSort | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetGenreQuery {
  genre: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: {
      totalCount: number;
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetGenreForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetGenreForEditQuery {
  genre: { id: string; name: string; wikidataId: number | null } | null;
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

export type GetEnginesIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: ResourceSort | null | undefined;
  nameContains?: string | null | undefined;
}>;

export interface GetEnginesIndexQuery {
  engines: {
    totalCount: number;
    nodes: Array<{
      id: string;
      name: string;
      gamesCount: number;
      coverGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetEngineQueryVariables = Exact<{
  id: string;
  sortBy?: ResourceGameSort | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetEngineQuery {
  engine: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: {
      totalCount: number;
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetEngineForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetEngineForEditQuery {
  engine: { id: string; name: string; wikidataId: number | null } | null;
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

export type GetSeriesIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: SeriesSort | null | undefined;
  nameContains?: string | null | undefined;
}>;

export interface GetSeriesIndexQuery {
  seriesList: {
    totalCount: number;
    nodes: Array<{
      id: string;
      name: string;
      gamesCount: number;
      firstReleaseYear: number | null;
      lastReleaseYear: number | null;
      coverGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetSeriesQueryVariables = Exact<{
  id: string;
  sortBy?: ResourceGameSort | null | undefined;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetSeriesQuery {
  series: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: {
      totalCount: number;
      nodes: Array<{
        id: string;
        name: string;
        coverUrl: string | null;
        releaseDate: string | null;
        isInLibrary: boolean | null;
      }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetSeriesForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetSeriesForEditQuery {
  series: { id: string; name: string; wikidataId: number | null } | null;
}

export type GetStoresQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  last?: number | null | undefined;
  before?: string | null | undefined;
}>;

export interface GetStoresQuery {
  stores: {
    nodes: Array<{ id: string; name: string }>;
    pageInfo: { hasNextPage: boolean; startCursor: string | null; endCursor: string | null };
  } | null;
}

export type GetStoreForEditQueryVariables = Exact<{
  id: string;
}>;

export interface GetStoreForEditQuery {
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
  last?: number | null | undefined;
  before?: string | null | undefined;
}>;

export interface GetActivityQuery {
  activity: {
    nodes: Array<{
      id: string;
      eventCategory: EventCategory;
      createdAt: string;
      completionStatusChange: {
        before: GamePurchaseCompletionStatus | null;
        after: GamePurchaseCompletionStatus | null;
      } | null;
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
    pageInfo: { hasNextPage: boolean; startCursor: string | null; endCursor: string | null };
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

export type GetGenresIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: ResourceSort | null | undefined;
  nameContains?: string | null | undefined;
}>;

export interface GetGenresIndexQuery {
  genres: {
    totalCount: number;
    nodes: Array<{
      id: string;
      name: string;
      gamesCount: number;
      coverGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetPlatformsIndexQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  sortBy?: ResourceSort | null | undefined;
  nameContains?: string | null | undefined;
}>;

export interface GetPlatformsIndexQuery {
  platforms: {
    totalCount: number;
    nodes: Array<{
      id: string;
      name: string;
      gamesCount: number;
      coverGames: Array<{ id: string; name: string; coverUrl: string | null }>;
    }>;
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  } | null;
}

export type GetUserProfileQueryVariables = Exact<{
  slug: string;
}>;

export interface GetUserProfileQuery {
  user: {
    id: string;
    username: string;
    slug: string;
    role: UserRole;
    privacy: UserPrivacy;
    banned: boolean;
    avatarUrl: string | null;
    isFollowed: boolean | null;
    hideDaysPlayed: boolean;
    libraryStatistics: {
      gamesCount: number;
      totalHoursPlayed: number;
      completionPercentage: number;
      averageRating: number | null;
    };
    favoritedGames: { totalCount: number };
    followers: { totalCount: number };
    following: { totalCount: number };
  } | null;
}

export type GetUserOverviewQueryVariables = Exact<{
  slug: string;
  favoritesCount: number;
  playingCount: number;
  topRatedCount: number;
}>;

export interface GetUserOverviewQuery {
  user: {
    id: string;
    bio: string | null;
    favoritedGames: { totalCount: number; nodes: Array<{ id: string; name: string; coverUrl: string | null }> };
    playing: {
      totalCount: number;
      nodes: Array<{
        startDate: string | null;
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        platforms: { nodes: Array<{ id: string; name: string }> };
        stores: { nodes: Array<{ id: string; name: string }> };
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
    topRated: {
      totalCount: number;
      nodes: Array<{
        id: string;
        hoursPlayed: number | null;
        completionStatus: GamePurchaseCompletionStatus | null;
        rating: number | null;
        game: { id: string; name: string; coverUrl: string | null };
      }>;
    };
  } | null;
}

export type GetUserFavoritesQueryVariables = Exact<{
  slug: string;
  first?: number | null | undefined;
  after?: string | null | undefined;
}>;

export interface GetUserFavoritesQuery {
  user: {
    id: string;
    favoritedGames: {
      totalCount: number;
      nodes: Array<{ id: string; name: string; coverUrl: string | null }>;
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  } | null;
}

export type GetUsersQueryVariables = Exact<{
  first?: number | null | undefined;
  after?: string | null | undefined;
  last?: number | null | undefined;
  before?: string | null | undefined;
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
    pageInfo: { hasNextPage: boolean; startCursor: string | null; endCursor: string | null };
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
  last?: number | null | undefined;
  before?: string | null | undefined;
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
        completionStatusChange: {
          before: GamePurchaseCompletionStatus | null;
          after: GamePurchaseCompletionStatus | null;
        } | null;
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
      pageInfo: { hasNextPage: boolean; startCursor: string | null; endCursor: string | null };
    };
  } | null;
}

export type GetCurrentUserProfileQueryVariables = Exact<{ [key: string]: never }>;

export interface GetCurrentUserProfileQuery {
  currentUser: {
    id: string;
    username: string;
    avatarUrl: string | null;
    bio: string | null;
    privacy: UserPrivacy;
    hideDaysPlayed: boolean;
  } | null;
}

export type GetCurrentUserSteamAccountQueryVariables = Exact<{ [key: string]: never }>;

export interface GetCurrentUserSteamAccountQuery {
  currentUser: { id: string; steamProfileUrl: string | null } | null;
}

export type GetCurrentUserAvatarQueryVariables = Exact<{ [key: string]: never }>;

export interface GetCurrentUserAvatarQuery {
  currentUser: { id: string; avatarUrl: string | null } | null;
}

export type GetCurrentUserPasskeysQueryVariables = Exact<{ [key: string]: never }>;

export interface GetCurrentUserPasskeysQuery {
  currentUser: {
    id: string;
    passkeys: Array<{
      id: string;
      nickname: string;
      backedUp: boolean;
      lastUsedAt: string | null;
      createdAt: string;
    }> | null;
  } | null;
}
