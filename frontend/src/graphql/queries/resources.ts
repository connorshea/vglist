import gql from "graphql-tag";

export const RESOURCE_GAME_FIELDS = gql`
  fragment ResourceGameFields on Game {
    id
    name
    coverUrl(size: SMALL)
    releaseDate
    isInLibrary
  }
`;

export const GET_PLATFORMS = gql`
  query GetPlatforms($first: Int, $after: String) {
    platforms(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_PLATFORM = gql`
  ${RESOURCE_GAME_FIELDS}

  query GetPlatform($id: ID!, $sortBy: ResourceGameSort, $first: Int, $after: String) {
    platform(id: $id) {
      id
      name
      wikidataId
      games(sortBy: $sortBy, first: $first, after: $after) {
        totalCount
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_PLATFORM_FOR_EDIT = gql`
  query GetPlatformForEdit($id: ID!) {
    platform(id: $id) {
      id
      name
      wikidataId
    }
  }
`;

export const GET_COMPANIES = gql`
  query GetCompanies($first: Int, $after: String) {
    companies(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_COMPANIES_INDEX = gql`
  query GetCompaniesIndex($first: Int, $after: String, $sortBy: ResourceSort, $nameContains: String) {
    companies(first: $first, after: $after, sortBy: $sortBy, nameContains: $nameContains) {
      totalCount
      nodes {
        id
        name
        gamesCount
        coverGames {
          id
          name
          coverUrl
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_COMPANY = gql`
  ${RESOURCE_GAME_FIELDS}

  query GetCompany($id: ID!, $sortBy: ResourceGameSort, $first: Int, $after: String, $developed: Boolean = true) {
    company(id: $id) {
      id
      name
      wikidataId
      developedCount: developedGames {
        totalCount
      }
      publishedCount: publishedGames {
        totalCount
      }
      developedGames(sortBy: $sortBy, first: $first, after: $after) @include(if: $developed) {
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
      publishedGames(sortBy: $sortBy, first: $first, after: $after) @skip(if: $developed) {
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_COMPANY_FOR_EDIT = gql`
  query GetCompanyForEdit($id: ID!) {
    company(id: $id) {
      id
      name
      wikidataId
    }
  }
`;

export const GET_GENRES = gql`
  query GetGenres($first: Int, $after: String) {
    genres(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_GENRE = gql`
  ${RESOURCE_GAME_FIELDS}

  query GetGenre($id: ID!, $sortBy: ResourceGameSort, $first: Int, $after: String) {
    genre(id: $id) {
      id
      name
      wikidataId
      games(sortBy: $sortBy, first: $first, after: $after) {
        totalCount
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_GENRE_FOR_EDIT = gql`
  query GetGenreForEdit($id: ID!) {
    genre(id: $id) {
      id
      name
      wikidataId
    }
  }
`;

export const GET_ENGINES = gql`
  query GetEngines($first: Int, $after: String) {
    engines(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_ENGINE = gql`
  ${RESOURCE_GAME_FIELDS}

  query GetEngine($id: ID!, $sortBy: ResourceGameSort, $first: Int, $after: String) {
    engine(id: $id) {
      id
      name
      wikidataId
      games(sortBy: $sortBy, first: $first, after: $after) {
        totalCount
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_ENGINE_FOR_EDIT = gql`
  query GetEngineForEdit($id: ID!) {
    engine(id: $id) {
      id
      name
      wikidataId
    }
  }
`;

export const GET_SERIES_LIST = gql`
  query GetSeriesList($first: Int, $after: String) {
    seriesList(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_SERIES_INDEX = gql`
  query GetSeriesIndex($first: Int, $after: String, $sortBy: SeriesSort, $nameContains: String) {
    seriesList(first: $first, after: $after, sortBy: $sortBy, nameContains: $nameContains) {
      totalCount
      nodes {
        id
        name
        gamesCount
        firstReleaseYear
        lastReleaseYear
        coverGames {
          id
          name
          coverUrl
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_SERIES = gql`
  ${RESOURCE_GAME_FIELDS}

  query GetSeries($id: ID!, $sortBy: ResourceGameSort, $first: Int, $after: String) {
    series(id: $id) {
      id
      name
      wikidataId
      games(sortBy: $sortBy, first: $first, after: $after) {
        totalCount
        nodes {
          ...ResourceGameFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_SERIES_FOR_EDIT = gql`
  query GetSeriesForEdit($id: ID!) {
    series(id: $id) {
      id
      name
      wikidataId
    }
  }
`;

export const GET_STORES = gql`
  query GetStores($first: Int, $after: String) {
    stores(first: $first, after: $after) {
      nodes {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_STORE_FOR_EDIT = gql`
  query GetStoreForEdit($id: ID!) {
    store(id: $id) {
      id
      name
    }
  }
`;

export const GLOBAL_SEARCH = gql`
  fragment SearchResultFields on SearchResultInterface {
    searchableId
    searchableType
    content
  }

  fragment GameSearchResultFields on GameSearchResult {
    ...SearchResultFields
    coverUrl(size: SMALL)
    developerName
    releaseDate
  }

  fragment UserSearchResultFields on UserSearchResult {
    ...SearchResultFields
    avatarUrl(size: SMALL)
    slug
  }

  query GlobalSearch($query: String!) {
    globalSearch(query: $query, first: 50) {
      nodes {
        ...SearchResultFields
        ...GameSearchResultFields
        ...UserSearchResultFields
      }
    }
  }
`;

export const GET_ACTIVITY = gql`
  query GetActivity($feedType: ActivityFeed, $first: Int, $after: String) {
    activity(feedType: $feedType, first: $first, after: $after) {
      nodes {
        id
        eventCategory
        createdAt
        completionStatusChange {
          before
          after
        }
        user {
          id
          username
          slug
          avatarUrl(size: SMALL)
        }
        eventable {
          ... on GamePurchase {
            game {
              id
              name
              coverUrl(size: SMALL)
            }
            completionStatus
            rating
          }
          ... on FavoriteGame {
            game {
              id
              name
              coverUrl(size: SMALL)
            }
          }
          ... on Relationship {
            followed {
              id
              username
              slug
              avatarUrl(size: SMALL)
            }
          }
          ... on User {
            id
            username
            slug
            avatarUrl(size: SMALL)
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_BASIC_SITE_STATISTICS = gql`
  query GetBasicSiteStatistics {
    basicSiteStatistics {
      games
      platforms
      series
      engines
      companies
      genres
    }
  }
`;

export const GET_GENRES_INDEX = gql`
  query GetGenresIndex($first: Int, $after: String, $sortBy: ResourceSort, $nameContains: String) {
    genres(first: $first, after: $after, sortBy: $sortBy, nameContains: $nameContains) {
      totalCount
      nodes {
        id
        name
        gamesCount
        coverGames {
          id
          name
          coverUrl
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_PLATFORMS_INDEX = gql`
  query GetPlatformsIndex($first: Int, $after: String, $sortBy: ResourceSort, $nameContains: String) {
    platforms(first: $first, after: $after, sortBy: $sortBy, nameContains: $nameContains) {
      totalCount
      nodes {
        id
        name
        gamesCount
        coverGames {
          id
          name
          coverUrl
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;
