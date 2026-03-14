import gql from "graphql-tag";

export const ADD_GAME_TO_LIBRARY = gql`
  mutation AddGameToLibrary(
    $gameId: ID!
    $completionStatus: GamePurchaseCompletionStatus
    $rating: Int
    $hoursPlayed: Float
    $comments: String
    $startDate: ISO8601Date
    $completionDate: ISO8601Date
    $platforms: [ID]
    $stores: [ID]
  ) {
    addGameToLibrary(
      gameId: $gameId
      completionStatus: $completionStatus
      rating: $rating
      hoursPlayed: $hoursPlayed
      comments: $comments
      startDate: $startDate
      completionDate: $completionDate
      platforms: $platforms
      stores: $stores
    ) {
      gamePurchase {
        id
        completionStatus
        rating
        hoursPlayed
        comments
        game {
          id
          name
        }
      }
    }
  }
`;

export const UPDATE_GAME_IN_LIBRARY = gql`
  mutation UpdateGameInLibrary(
    $gamePurchaseId: ID!
    $completionStatus: GamePurchaseCompletionStatus
    $rating: Int
    $hoursPlayed: Float
    $comments: String
    $startDate: ISO8601Date
    $completionDate: ISO8601Date
    $replayCount: Int
    $platforms: [ID]
    $stores: [ID]
  ) {
    updateGameInLibrary(
      gamePurchaseId: $gamePurchaseId
      completionStatus: $completionStatus
      rating: $rating
      hoursPlayed: $hoursPlayed
      comments: $comments
      startDate: $startDate
      completionDate: $completionDate
      replayCount: $replayCount
      platforms: $platforms
      stores: $stores
    ) {
      gamePurchase {
        id
        completionStatus
        rating
        hoursPlayed
        comments
      }
    }
  }
`;

export const REMOVE_GAME_FROM_LIBRARY = gql`
  mutation RemoveGameFromLibrary($gamePurchaseId: ID!) {
    removeGameFromLibrary(gamePurchaseId: $gamePurchaseId) {
      game {
        id
      }
    }
  }
`;

export const FAVORITE_GAME = gql`
  mutation FavoriteGame($gameId: ID!) {
    favoriteGame(gameId: $gameId) {
      game {
        id
        name
      }
    }
  }
`;

export const UNFAVORITE_GAME = gql`
  mutation UnfavoriteGame($gameId: ID!) {
    unfavoriteGame(gameId: $gameId) {
      game {
        id
        name
      }
    }
  }
`;
