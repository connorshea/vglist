import gql from "graphql-tag";

// Queries for the games index at /games: one grid with sort tabs, platform
// pills and a "More filters" popover.

export const GAME_TILE_FIELDS = gql`
  fragment GameTileFields on Game {
    id
    name
    releaseDate
    avgRating
    coverUrl(size: MEDIUM)
    isInLibrary
    libraryCompletionStatus
    ownerCount
  }
`;

export const GET_GAMES_INDEX = gql`
  ${GAME_TILE_FIELDS}
  query GetGamesIndex(
    $first: Int
    $after: String
    $sortBy: GameSort
    $onPlatform: ID
    $byGenre: ID
    $byEngine: ID
    $fromYear: Int
    $toYear: Int
    $excludeLibrary: Boolean
    $withCount: Boolean!
  ) {
    games(
      first: $first
      after: $after
      sortBy: $sortBy
      onPlatform: $onPlatform
      byGenre: $byGenre
      byEngine: $byEngine
      fromYear: $fromYear
      toYear: $toYear
      excludeLibrary: $excludeLibrary
    ) {
      nodes {
        ...GameTileFields
      }
      totalCount @include(if: $withCount)
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

// How many games the filters being edited in the popover would show under the
// current sort, for its "Show N games" button.
export const GET_GAMES_INDEX_COUNT = gql`
  query GetGamesIndexCount(
    $sortBy: GameSort
    $onPlatform: ID
    $byGenre: ID
    $byEngine: ID
    $fromYear: Int
    $toYear: Int
    $excludeLibrary: Boolean
  ) {
    games(
      sortBy: $sortBy
      onPlatform: $onPlatform
      byGenre: $byGenre
      byEngine: $byEngine
      fromYear: $fromYear
      toYear: $toYear
      excludeLibrary: $excludeLibrary
    ) {
      totalCount
    }
  }
`;

// The platform and genre pills, the site-wide game count for the page header,
// and the names of whichever filters are set in the URL (which only carries
// IDs).
export const GET_GAMES_INDEX_FILTERS = gql`
  query GetGamesIndexFilters(
    $platformId: ID!
    $hasPlatform: Boolean!
    $genreId: ID!
    $hasGenre: Boolean!
    $engineId: ID!
    $hasEngine: Boolean!
  ) {
    basicSiteStatistics {
      games
    }
    platforms(first: 6, sortBy: MOST_GAMES) {
      nodes {
        id
        name
      }
    }
    genres(first: 6, sortBy: MOST_GAMES) {
      nodes {
        id
        name
      }
    }
    platform(id: $platformId) @include(if: $hasPlatform) {
      id
      name
    }
    genre(id: $genreId) @include(if: $hasGenre) {
      id
      name
    }
    engine(id: $engineId) @include(if: $hasEngine) {
      id
      name
    }
  }
`;

export const SEARCH_PLATFORMS_FOR_FILTER = gql`
  query SearchPlatformsForFilter($query: String!) {
    platformSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_GENRES_FOR_FILTER = gql`
  query SearchGenresForFilter($query: String!) {
    genreSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_ENGINES_FOR_FILTER = gql`
  query SearchEnginesForFilter($query: String!) {
    engineSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;
