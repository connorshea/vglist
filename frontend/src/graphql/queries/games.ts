import gql from "graphql-tag";

export const GAME_FIELDS = gql`
  fragment GameFields on Game {
    id
    name
    releaseDate
    avgRating
    coverUrl(size: MEDIUM)
    developers {
      nodes {
        id
        name
      }
    }
    publishers {
      nodes {
        id
        name
      }
    }
    platforms {
      nodes {
        id
        name
      }
    }
    genres {
      nodes {
        id
        name
      }
    }
    engines {
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

export const GET_GAME = gql`
  ${GAME_FIELDS}
  query GetGame($id: ID!) {
    game(id: $id) {
      ...GameFields
      isFavorited
      isInLibrary
      gamePurchaseId
      wikidataId
      steamAppIds
      pcgamingwikiId
      mobygamesId
      giantbombId
      epicGamesStoreId
      gogId
      igdbId
      owners(first: 6) {
        nodes {
          id
          slug
          username
          avatarUrl(size: SMALL)
        }
        totalCount
      }
      favoriters(first: 6) {
        nodes {
          id
          slug
          username
          avatarUrl(size: SMALL)
        }
        totalCount
      }
    }
  }
`;

export const GET_GAMES = gql`
  query GetGames($first: Int, $after: String) {
    games(first: $first, after: $after) {
      nodes {
        id
        name
        releaseDate
        coverUrl(size: SMALL)
        developers(first: 3) {
          nodes {
            name
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

export const GET_RECENT_GAMES = gql`
  query GetRecentGames($first: Int) {
    games(first: $first, sortBy: RECENTLY_UPDATED) {
      nodes {
        id
        name
        coverUrl(size: SMALL)
        platforms {
          nodes {
            id
            name
          }
        }
        developers {
          nodes {
            id
            name
          }
        }
      }
    }
  }
`;

export const GET_HERO_COVERS = gql`
  query GetHeroCovers {
    games(first: 100, sortBy: RECENTLY_UPDATED) {
      nodes {
        id
        coverUrl(size: SMALL)
      }
    }
  }
`;

export const GET_GAME_PURCHASE = gql`
  query GetGamePurchase($id: ID!) {
    gamePurchase(id: $id) {
      id
      completionStatus
      rating
      hoursPlayed
      replayCount
      comments
      startDate
      completionDate
      platforms {
        nodes {
          id
          name
        }
      }
      stores {
        nodes {
          id
          name
        }
      }
    }
  }
`;
