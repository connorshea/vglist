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
      ratingCount
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

export const GET_GAME_REVIEWS = gql`
  query GetGameReviews($id: ID!, $sortBy: GameReviewSort, $first: Int) {
    game(id: $id) {
      id
      reviews(sortBy: $sortBy, first: $first) {
        totalCount
        nodes {
          id
          comments
          rating
          hoursPlayed
          replayCount
          completionStatus
          updatedAt
          user {
            id
            username
            slug
            avatarUrl(size: SMALL)
          }
          platforms {
            nodes {
              id
              name
            }
          }
        }
      }
    }
  }
`;

export const GET_GAME_ACTIVITY = gql`
  query GetGameActivity($id: ID!, $first: Int) {
    game(id: $id) {
      id
      activity(first: $first) {
        nodes {
          id
          eventCategory
          createdAt
          user {
            id
            username
            slug
            avatarUrl(size: SMALL)
          }
          completionStatusChange {
            after
          }
          eventable {
            ... on GamePurchase {
              id
              completionStatus
            }
          }
        }
      }
    }
  }
`;
