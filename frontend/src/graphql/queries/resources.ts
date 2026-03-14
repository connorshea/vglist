import gql from 'graphql-tag'

export const GET_PLATFORMS = gql`
  query GetPlatforms($first: Int, $after: String) {
    platforms(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_PLATFORM = gql`
  query GetPlatform($id: ID!) {
    platform(id: $id) {
      id
      name
      wikidataId
      games(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`

export const GET_COMPANIES = gql`
  query GetCompanies($first: Int, $after: String) {
    companies(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_COMPANY = gql`
  query GetCompany($id: ID!) {
    company(id: $id) {
      id
      name
      wikidataId
      developedGames(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
      publishedGames(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`

export const GET_GENRES = gql`
  query GetGenres($first: Int, $after: String) {
    genres(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_GENRE = gql`
  query GetGenre($id: ID!) {
    genre(id: $id) {
      id
      name
      wikidataId
      games(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`

export const GET_ENGINES = gql`
  query GetEngines($first: Int, $after: String) {
    engines(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_ENGINE = gql`
  query GetEngine($id: ID!) {
    engine(id: $id) {
      id
      name
      wikidataId
      games(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`

export const GET_SERIES_LIST = gql`
  query GetSeriesList($first: Int, $after: String) {
    seriesList(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_SERIES = gql`
  query GetSeries($id: ID!) {
    series(id: $id) {
      id
      name
      wikidataId
      games(first: 30) {
        nodes { id name coverUrl(size: SMALL) }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`

export const GET_STORES = gql`
  query GetStores($first: Int, $after: String) {
    stores(first: $first, after: $after) {
      nodes { id name }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_STORE = gql`
  query GetStore($id: ID!) {
    store(id: $id) {
      id
      name
    }
  }
`

export const GLOBAL_SEARCH = gql`
  query GlobalSearch($query: String!) {
    globalSearch(query: $query) {
      nodes {
        searchableId
        searchableType
        content
      }
    }
  }
`

export const GET_ACTIVITY = gql`
  query GetActivity($feedType: ActivityFeedType, $first: Int, $after: String) {
    activity(feedType: $feedType, first: $first, after: $after) {
      nodes {
        id
        eventCategory
        createdAt
        user { id username slug avatarUrl(size: SMALL) }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
`

export const GET_BASIC_SITE_STATISTICS = gql`
  query GetBasicSiteStatistics {
    basicSiteStatistics {
      gamesCount
      platformsCount
      seriesCount
      enginesCount
      companiesCount
      genresCount
      storesCount
      usersCount
      gamePurchasesCount
    }
  }
`
