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

export const GET_SITE_STATISTICS = gql`
  query GetSiteStatistics($first: Int, $after: String) {
    siteStatistics(first: $first, after: $after) {
      nodes {
        id
        timestamp
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
        gamesWithCovers
        gamesWithReleaseDates
        bannedUsers
        unmatchedGames
        mobygamesIds
        pcgamingwikiIds
        wikidataIds
        giantbombIds
        steamAppIds
        epicGamesStoreIds
        gogIds
        igdbIds
        companyVersions
        gameVersions
        genreVersions
        engineVersions
        platformVersions
        seriesVersions
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

// Candidates for the game to keep when merging a duplicate into it. Owner
// counts and release dates help tell the canonical entry from the duplicate.
export const SEARCH_GAMES_TO_MERGE = gql`
  query SearchGamesToMerge($query: String!) {
    gameSearch(query: $query, first: 8) {
      nodes {
        id
        name
        releaseDate
        coverUrl(size: SMALL)
        ownerCount
      }
    }
  }
`;
