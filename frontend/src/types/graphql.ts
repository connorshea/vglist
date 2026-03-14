// This file is a placeholder that will be overwritten by graphql-codegen.
// Run `yarn codegen` to regenerate from the GraphQL schema and queries.
//
// Type names follow graphql-codegen conventions:
//   - Query results: {OperationName}Query
//   - Mutation results: {OperationName}Mutation

import type { PageInfo } from "./index";

// Helper for paginated connections
interface Connection<T> {
  nodes: T[];
  pageInfo: PageInfo;
}

interface BasicNode {
  id: string;
  name: string;
}

interface GameCardNode {
  id: string;
  name: string;
  coverUrl: string | null;
}

interface UserBasicNode {
  id: string;
  username: string;
  slug: string;
  avatarUrl: string | null;
}

// Query types

export interface GetActivityQuery {
  activity: Connection<{
    id: string;
    eventCategory: string;
    createdAt: string;
    user: UserBasicNode;
  }>;
}

export interface GetCompaniesQuery {
  companies: Connection<BasicNode>;
}

export interface GetCompanyQuery {
  company: {
    id: string;
    name: string;
    wikidataId: number | null;
    developedGames: Connection<GameCardNode>;
    publishedGames: Connection<GameCardNode>;
  };
}

export interface GetEnginesQuery {
  engines: Connection<BasicNode>;
}

export interface GetEngineQuery {
  engine: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: Connection<GameCardNode>;
  };
}

export interface GetGamesQuery {
  games: Connection<{
    id: string;
    name: string;
    releaseDate: string | null;
    coverUrl: string | null;
    developers: { nodes: BasicNode[] };
  }>;
}

export interface GetGameQuery {
  game: {
    id: string;
    name: string;
    releaseDate: string | null;
    avgRating: number | null;
    coverUrl: string | null;
    wikidataId: number | null;
    steamAppIds: number[];
    pcgamingwikiId: string | null;
    mobygamesId: string | null;
    giantbombId: string | null;
    epicGamesStoreId: string | null;
    gogId: string | null;
    igdbId: string | null;
    developers: { nodes: BasicNode[] };
    publishers: { nodes: BasicNode[] };
    platforms: { nodes: BasicNode[] };
    genres: { nodes: BasicNode[] };
    engines: { nodes: BasicNode[] };
    series: { id: string; name: string } | null;
  };
}

export interface GetGenresQuery {
  genres: Connection<BasicNode>;
}

export interface GetGenreQuery {
  genre: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: Connection<GameCardNode>;
  };
}

export interface GetPlatformsQuery {
  platforms: Connection<BasicNode>;
}

export interface GetPlatformQuery {
  platform: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: Connection<GameCardNode>;
  };
}

export interface GetSeriesListQuery {
  seriesList: Connection<BasicNode>;
}

export interface GetSeriesQuery {
  series: {
    id: string;
    name: string;
    wikidataId: number | null;
    games: Connection<GameCardNode>;
  };
}

export interface GetStoresQuery {
  stores: Connection<BasicNode>;
}

export interface GetStoreQuery {
  store: {
    id: string;
    name: string;
  };
}

export interface GetUsersQuery {
  users: Connection<{
    id: string;
    username: string;
    slug: string;
    avatarUrl: string | null;
    gamePurchases: { totalCount: number };
  }>;
}

export interface GetUserQuery {
  user: {
    id: string;
    username: string;
    bio: string | null;
    slug: string;
    role: string;
    privacy: string;
    createdAt: string;
    banned: boolean;
    avatarUrl: string | null;
    isFollowed: boolean | null;
    hideDaysPlayed: boolean;
    gamePurchases: Connection<{
      id: string;
      game: GameCardNode;
      hoursPlayed: number | null;
      completionStatus: string | null;
      rating: number | null;
    }>;
    followers: {
      totalCount: number;
      nodes: UserBasicNode[];
    };
    following: {
      totalCount: number;
      nodes: UserBasicNode[];
    };
    favoritedGames: { nodes: GameCardNode[] };
  };
}

export interface SearchResultNode {
  searchableId: string;
  searchableType: string;
  content: string;
  // Game-specific fields
  coverUrl?: string | null;
  developerName?: string | null;
  releaseDate?: string | null;
  // User-specific fields
  avatarUrl?: string | null;
  slug?: string;
}

export interface GlobalSearchQuery {
  globalSearch: {
    nodes: SearchResultNode[];
  };
}

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

export interface GetCurrentUserProfileQuery {
  currentUser: {
    id: string;
    bio: string | null;
    privacy: string;
    hideDaysPlayed: boolean;
  };
}

// Mutation types

export interface UpdateUserMutation {
  updateUser: {
    user: { id: string; bio: string | null; privacy: string; hideDaysPlayed: boolean };
    errors: string[];
  };
}

export interface ExportLibraryMutation {
  exportLibrary: {
    libraryJson: string;
    errors: string[];
  };
}

export interface ResetApiTokenMutation {
  resetApiToken: {
    apiToken: string;
    errors: string[];
  };
}
