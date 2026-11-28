import gql from "graphql-tag";

// These queries run for signed-out visitors too, which are held to the API's
// 500-point complexity limit (see GraphqlController#first_party?). Nested
// connections are charged as if they could return 100 records unless they
// set `first:`, so every one here does.
//
// `spec/requests/api/search_complexity_spec.rb` runs these documents
// anonymously to keep them under the limit.

const SEARCH_GAME_FIELDS = gql`
  fragment SearchGameFields on Game {
    id
    name
    releaseDate
    coverUrl(size: SMALL)
    isInLibrary
    platforms(first: 8) {
      totalCount
      nodes {
        id
        name
      }
    }
    developers(first: 3) {
      nodes {
        id
        name
      }
    }
    publishers(first: 3) {
      nodes {
        id
        name
      }
    }
    series {
      id
      name
    }
  }
`;

const SEARCH_USER_FIELDS = gql`
  fragment SearchUserFields on User {
    id
    username
    slug
    avatarUrl(size: SMALL)
  }
`;

// Top hits and totals for every type, for the "All" tab and the tab counts.
export const SEARCH_OVERVIEW = gql`
  ${SEARCH_GAME_FIELDS}
  ${SEARCH_USER_FIELDS}

  query SearchOverview($query: String!) {
    games: gameSearch(query: $query, first: 5) {
      totalCount
      nodes {
        ...SearchGameFields
      }
    }
    companies: companySearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    platforms: platformSearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    series: seriesSearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    engines: engineSearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    genres: genreSearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    stores: storeSearch(query: $query, first: 3) {
      totalCount
      nodes {
        id
        name
      }
    }
    users: userSearch(query: $query, first: 3) {
      totalCount
      nodes {
        ...SearchUserFields
      }
    }
  }
`;

// One page of a single type. Exactly one of the `$<tab>` flags is true, so
// only that tab's field is fetched (and charged for).
export const SEARCH_TAB = gql`
  ${SEARCH_GAME_FIELDS}
  ${SEARCH_USER_FIELDS}

  query SearchTab(
    $query: String!
    $first: Int!
    $after: String
    $games: Boolean!
    $companies: Boolean!
    $platforms: Boolean!
    $series: Boolean!
    $engines: Boolean!
    $genres: Boolean!
    $stores: Boolean!
    $users: Boolean!
  ) {
    games: gameSearch(query: $query, first: $first, after: $after) @include(if: $games) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        ...SearchGameFields
      }
    }
    companies: companySearch(query: $query, first: $first, after: $after) @include(if: $companies) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    platforms: platformSearch(query: $query, first: $first, after: $after) @include(if: $platforms) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    series: seriesSearch(query: $query, first: $first, after: $after) @include(if: $series) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    engines: engineSearch(query: $query, first: $first, after: $after) @include(if: $engines) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    genres: genreSearch(query: $query, first: $first, after: $after) @include(if: $genres) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    stores: storeSearch(query: $query, first: $first, after: $after) @include(if: $stores) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        id
        name
      }
    }
    users: userSearch(query: $query, first: $first, after: $after) @include(if: $users) {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        ...SearchUserFields
      }
    }
  }
`;
