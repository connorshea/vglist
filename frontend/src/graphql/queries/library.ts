import gql from "graphql-tag";

// The counts in a user's library's filter rail. They're for the whole library,
// so they don't change with the filters.
export const GET_LIBRARY_PAGE = gql`
  query GetLibraryPage($slug: String!) {
    user(slug: $slug) {
      id
      hideDaysPlayed
      libraryStatistics {
        gamesCount
        statusCounts {
          status
          count
        }
        platformCounts {
          platform {
            id
            name
          }
          count
        }
        storeCounts {
          store {
            id
            name
          }
          count
        }
      }
    }
  }
`;

// What a game tile in the library grid shows.
export const LIBRARY_GAME_PURCHASE_FIELDS = gql`
  fragment LibraryGamePurchaseFields on GamePurchase {
    id
    game {
      id
      name
      coverUrl(size: SMALL)
    }
    hoursPlayed
    completionStatus
    rating
  }
`;

// What a Playing card shows: a game tile's fields, plus where and when the
// game was started.
export const LIBRARY_PLAYING_PURCHASE_FIELDS = gql`
  fragment LibraryPlayingPurchaseFields on GamePurchase {
    ...LibraryGamePurchaseFields
    startDate
    platforms(first: 3) {
      nodes {
        id
        name
      }
    }
    stores(first: 3) {
      nodes {
        id
        name
      }
    }
  }
  ${LIBRARY_GAME_PURCHASE_FIELDS}
`;

// One page of the library, for a single status or for the ungrouped grid.
export const GET_LIBRARY_GAMES = gql`
  query GetLibraryGames(
    $slug: String!
    $first: Int
    $after: String
    $completionStatus: GamePurchaseCompletionStatus
    $noCompletionStatus: Boolean
    $search: String
    $sortBy: GamePurchaseSort
    $platformIds: [ID!]
    $storeIds: [ID!]
    $minRating: Int
    $maxRating: Int
  ) {
    user(slug: $slug) {
      id
      gamePurchases(
        first: $first
        after: $after
        completionStatus: $completionStatus
        noCompletionStatus: $noCompletionStatus
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        totalCount
        nodes {
          ...LibraryGamePurchaseFields
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
  ${LIBRARY_GAME_PURCHASE_FIELDS}
`;

// The first few games of each status (and of the games with no status), for
// the library grouped into shelves.
// Fetched as one request so the shelves load together.
export const GET_LIBRARY_SHELVES = gql`
  query GetLibraryShelves(
    $slug: String!
    $first: Int!
    $search: String
    $sortBy: GamePurchaseSort
    $platformIds: [ID!]
    $storeIds: [ID!]
    $minRating: Int
    $maxRating: Int
  ) {
    user(slug: $slug) {
      id
      inProgress: gamePurchases(
        first: $first
        completionStatus: IN_PROGRESS
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        totalCount
        nodes {
          ...LibraryPlayingPurchaseFields
        }
      }
      paused: gamePurchases(
        first: $first
        completionStatus: PAUSED
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      completed: gamePurchases(
        first: $first
        completionStatus: COMPLETED
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      fullyCompleted: gamePurchases(
        first: $first
        completionStatus: FULLY_COMPLETED
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      unplayed: gamePurchases(
        first: $first
        completionStatus: UNPLAYED
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      dropped: gamePurchases(
        first: $first
        completionStatus: DROPPED
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      notApplicable: gamePurchases(
        first: $first
        completionStatus: NOT_APPLICABLE
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
      noStatus: gamePurchases(
        first: $first
        noCompletionStatus: true
        search: $search
        sortBy: $sortBy
        platformIds: $platformIds
        storeIds: $storeIds
        minRating: $minRating
        maxRating: $maxRating
      ) {
        ...LibraryShelfFields
      }
    }
  }
  fragment LibraryShelfFields on GamePurchaseConnection {
    totalCount
    nodes {
      ...LibraryGamePurchaseFields
    }
  }
  ${LIBRARY_PLAYING_PURCHASE_FIELDS}
`;

// The game's platforms, which the library entry form offers when it's opened
// from the library rather than from the game's page.
export const GET_LIBRARY_ENTRY_GAME = gql`
  query GetLibraryEntryGame($id: ID!) {
    game(id: $id) {
      id
      platforms {
        nodes {
          id
          name
        }
      }
    }
  }
`;
