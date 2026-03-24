import gql from "graphql-tag";

export const GET_LIVE_STATISTICS = gql`
  query GetLiveStatistics {
    liveStatistics {
      users
      games
      platforms
      series
      engines
      companies
      genres
      stores
      events
      gamePurchases
      relationships
      bannedUsers
      gamesWithCovers
      gamesWithReleaseDates
      mobygamesIds
      pcgamingwikiIds
      wikidataIds
      giantbombIds
      steamAppIds
      epicGamesStoreIds
      gogIds
      igdbIds
    }
  }
`;

export const GET_STEAM_BLOCKLIST = gql`
  query GetSteamBlocklist($first: Int, $after: String) {
    steamBlocklist(first: $first, after: $after) {
      nodes {
        id
        name
        steamAppId
        user {
          id
          username
          slug
        }
        createdAt
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_WIKIDATA_BLOCKLIST = gql`
  query GetWikidataBlocklist($first: Int, $after: String) {
    wikidataBlocklist(first: $first, after: $after) {
      nodes {
        id
        name
        wikidataId
        user {
          id
          username
          slug
        }
        createdAt
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_UNMATCHED_GAMES = gql`
  query GetUnmatchedGames($first: Int, $after: String) {
    groupedUnmatchedGames(first: $first, after: $after) {
      nodes {
        externalServiceName
        externalServiceId
        name
        count
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;
