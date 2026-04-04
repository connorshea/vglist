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

export const DELETE_GAME = gql`
  mutation DeleteGame($gameId: ID!) {
    deleteGame(gameId: $gameId) {
      deleted
    }
  }
`;

export const REMOVE_GAME_COVER = gql`
  mutation RemoveGameCover($gameId: ID!) {
    removeGameCover(gameId: $gameId) {
      game {
        id
      }
    }
  }
`;

export const CREATE_GAME = gql`
  mutation CreateGame(
    $name: String!
    $releaseDate: ISO8601Date
    $wikidataId: ID
    $seriesId: ID
    $platformIds: [ID!]
    $developerIds: [ID!]
    $publisherIds: [ID!]
    $genreIds: [ID!]
    $engineIds: [ID!]
    $pcgamingwikiId: String
    $mobygamesId: Int
    $giantbombId: String
    $epicGamesStoreId: String
    $gogId: String
    $igdbId: String
    $steamAppIds: [Int!]
  ) {
    createGame(
      name: $name
      releaseDate: $releaseDate
      wikidataId: $wikidataId
      seriesId: $seriesId
      platformIds: $platformIds
      developerIds: $developerIds
      publisherIds: $publisherIds
      genreIds: $genreIds
      engineIds: $engineIds
      pcgamingwikiId: $pcgamingwikiId
      mobygamesId: $mobygamesId
      giantbombId: $giantbombId
      epicGamesStoreId: $epicGamesStoreId
      gogId: $gogId
      igdbId: $igdbId
      steamAppIds: $steamAppIds
    ) {
      game {
        id
        name
      }
    }
  }
`;

export const UPDATE_GAME = gql`
  mutation UpdateGame(
    $gameId: ID!
    $name: String
    $releaseDate: ISO8601Date
    $wikidataId: ID
    $seriesId: ID
    $platformIds: [ID!]
    $developerIds: [ID!]
    $publisherIds: [ID!]
    $genreIds: [ID!]
    $engineIds: [ID!]
    $pcgamingwikiId: String
    $mobygamesId: Int
    $giantbombId: String
    $epicGamesStoreId: String
    $gogId: String
    $igdbId: String
    $steamAppIds: [Int!]
  ) {
    updateGame(
      gameId: $gameId
      name: $name
      releaseDate: $releaseDate
      wikidataId: $wikidataId
      seriesId: $seriesId
      platformIds: $platformIds
      developerIds: $developerIds
      publisherIds: $publisherIds
      genreIds: $genreIds
      engineIds: $engineIds
      pcgamingwikiId: $pcgamingwikiId
      mobygamesId: $mobygamesId
      giantbombId: $giantbombId
      epicGamesStoreId: $epicGamesStoreId
      gogId: $gogId
      igdbId: $igdbId
      steamAppIds: $steamAppIds
    ) {
      game {
        id
        name
      }
    }
  }
`;
