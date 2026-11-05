import gql from "graphql-tag";

// The header, navigation and filter rail of a user's library page. The
// statistics are for the whole library, so they don't change with the filters.
export const GET_LIBRARY_PAGE = gql`
  query GetLibraryPage($slug: String!) {
    user(slug: $slug) {
      id
      username
      slug
      privacy
      avatarUrl(size: SMALL)
      hideDaysPlayed
      libraryStatistics {
        gamesCount
        totalHoursPlayed
        completionPercentage
        averageRating
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
      favoritedGames {
        totalCount
      }
      followers {
        totalCount
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

// One page of the library, for a single status or for the ungrouped grid.
export const GET_LIBRARY_GAMES = gql`
  query GetLibraryGames(
    $slug: String!
    $first: Int
    $after: String
    $completionStatus: GamePurchaseCompletionStatus
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

// The first few games of each status, for the library grouped into shelves.
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
          ...LibraryGamePurchaseFields
          # The Playing shelf's cards also say where and when the game was started.
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
    }
  }
  fragment LibraryShelfFields on GamePurchaseConnection {
    totalCount
    nodes {
      ...LibraryGamePurchaseFields
    }
  }
  ${LIBRARY_GAME_PURCHASE_FIELDS}
`;
