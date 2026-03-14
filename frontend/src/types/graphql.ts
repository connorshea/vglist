import type { PageInfo } from './index'

// Connection helper for paginated GraphQL responses
export interface Connection<T> {
  nodes: T[]
  pageInfo: PageInfo
}

// Shared node types matching GraphQL selection sets
export interface BasicNode {
  id: string
  name: string
}

export interface GameCardNode {
  id: string
  name: string
  coverUrl: string | null
}

// Activity
export interface ActivityEventNode {
  id: string
  eventCategory: string
  createdAt: string
  user: {
    id: string
    username: string
    slug: string
    avatarUrl: string | null
  }
}

export interface GetActivityData {
  activity: Connection<ActivityEventNode>
}

// Companies
export interface GetCompaniesData {
  companies: Connection<BasicNode>
}

export interface GetCompanyData {
  company: {
    id: string
    name: string
    wikidataId: number | null
    developedGames: Connection<GameCardNode>
    publishedGames: Connection<GameCardNode>
  }
}

// Engines
export interface GetEnginesData {
  engines: Connection<BasicNode>
}

export interface GetEngineData {
  engine: {
    id: string
    name: string
    wikidataId: number | null
    games: Connection<GameCardNode>
  }
}

// Games
export interface GameListNode {
  id: string
  name: string
  releaseDate: string | null
  coverUrl: string | null
  developers: { nodes: BasicNode[] }
}

export interface GetGamesData {
  games: Connection<GameListNode>
}

export interface GetGameData {
  game: {
    id: string
    name: string
    releaseDate: string | null
    avgRating: number | null
    coverUrl: string | null
    wikidataId: number | null
    steamAppIds: number[]
    pcgamingwikiId: string | null
    mobygamesId: string | null
    giantbombId: string | null
    epicGamesStoreId: string | null
    gogId: string | null
    igdbId: string | null
    developers: { nodes: BasicNode[] }
    publishers: { nodes: BasicNode[] }
    platforms: { nodes: BasicNode[] }
    genres: { nodes: BasicNode[] }
    engines: { nodes: BasicNode[] }
    series: { id: string; name: string } | null
  }
}

// Genres
export interface GetGenresData {
  genres: Connection<BasicNode>
}

export interface GetGenreData {
  genre: {
    id: string
    name: string
    wikidataId: number | null
    games: Connection<GameCardNode>
  }
}

// Platforms
export interface GetPlatformsData {
  platforms: Connection<BasicNode>
}

export interface GetPlatformData {
  platform: {
    id: string
    name: string
    wikidataId: number | null
    games: Connection<GameCardNode>
  }
}

// Series
export interface GetSeriesListData {
  seriesList: Connection<BasicNode>
}

export interface GetSeriesData {
  series: {
    id: string
    name: string
    wikidataId: number | null
    games: Connection<GameCardNode>
  }
}

// Stores
export interface GetStoresData {
  stores: Connection<BasicNode>
}

export interface GetStoreData {
  store: {
    id: string
    name: string
  }
}

// Users
export interface UserListNode {
  id: string
  username: string
  slug: string
  avatarUrl: string | null
  gamePurchases: { totalCount: number }
}

export interface GetUsersData {
  users: Connection<UserListNode>
}

interface UserBasicNode {
  id: string
  username: string
  avatarUrl: string | null
}

export interface GetUserData {
  user: {
    id: string
    username: string
    bio: string | null
    slug: string
    role: string
    privacy: string
    createdAt: string
    banned: boolean
    avatarUrl: string | null
    isFollowed: boolean | null
    hideDaysPlayed: boolean
    gamePurchases: Connection<{
      id: string
      game: GameCardNode
      hoursPlayed: number | null
      completionStatus: string | null
      rating: number | null
    }>
    followers: { totalCount: number; nodes?: UserBasicNode[] }
    following: { totalCount: number; nodes?: UserBasicNode[] }
    favoritedGames: { nodes: GameCardNode[] }
  }
}

// Search
export interface SearchResultNode {
  searchableId: string
  searchableType: string
  content: string
}

export interface GlobalSearchData {
  globalSearch: { nodes: SearchResultNode[] }
}

// Statistics
export interface GetBasicSiteStatisticsData {
  basicSiteStatistics: {
    gamesCount: number
    platformsCount: number
    seriesCount: number
    enginesCount: number
    companiesCount: number
    genresCount: number
    storesCount: number
    usersCount: number
    gamePurchasesCount: number
  }
}

// Settings
export interface GetCurrentUserProfileData {
  currentUser: {
    id: string
    bio: string | null
    privacy: string
    hideDaysPlayed: boolean
  }
}

// Mutation responses
export interface UpdateUserData {
  updateUser: {
    user: { id: string; bio: string | null; privacy: string; hideDaysPlayed: boolean }
    errors: string[]
  }
}

export interface ExportLibraryData {
  exportLibrary: {
    libraryJson: string
    errors: string[]
  }
}

export interface ResetApiTokenData {
  resetApiToken: {
    apiToken: string
    errors: string[]
  }
}
