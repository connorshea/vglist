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
      wikidataId
      steamAppIds
      pcgamingwikiId
      mobygamesId
      giantbombId
      epicGamesStoreId
      gogId
      igdbId
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
        developers {
          nodes {
            id
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

export const SEARCH_GAMES = gql`
  query SearchGames($query: String!) {
    gameSearch(query: $query) {
      nodes {
        id
        name
        releaseDate
        coverUrl(size: SMALL)
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
