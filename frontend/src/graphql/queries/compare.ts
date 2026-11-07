import gql from "graphql-tag";
import { LIBRARY_GAME_PURCHASE_FIELDS } from "@/graphql/queries/library";

// A user on the comparison page: their avatar and name in the header.
const COMPARISON_USER_FIELDS = gql`
  fragment ComparisonUserFields on User {
    id
    username
    slug
    avatarUrl(size: SMALL)
  }
`;

// The header, the overlap band and the tabs' counts, plus the "Only in…"
// shelves on the Overview tab.
export const GET_LIBRARY_COMPARISON = gql`
  query GetLibraryComparison($userASlug: String!, $userBSlug: String!, $shelfCount: Int!) {
    libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
      userA {
        ...ComparisonUserFields
      }
      userB {
        ...ComparisonUserFields
      }
      inCommonCount
      onlyACount
      onlyBCount
      bothRatedCount
      averageRatingGap
      onlyA(first: $shelfCount, sortBy: HIGHEST_RATING) {
        nodes {
          ...LibraryGamePurchaseFields
        }
      }
      onlyB(first: $shelfCount, sortBy: HIGHEST_RATING) {
        nodes {
          ...LibraryGamePurchaseFields
        }
      }
    }
  }
  ${COMPARISON_USER_FIELDS}
  ${LIBRARY_GAME_PURCHASE_FIELDS}
`;

// The games both users own, as rows of the In common table.
export const GET_COMPARISON_IN_COMMON = gql`
  query GetComparisonInCommon(
    $userASlug: String!
    $userBSlug: String!
    $first: Int!
    $after: String
    $sortBy: LibraryComparisonSort
    $search: String
    $bothRated: Boolean
  ) {
    libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
      inCommon(first: $first, after: $after, sortBy: $sortBy, search: $search, bothRated: $bothRated) {
        totalCount
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          game {
            id
            name
            coverUrl(size: SMALL)
            developers(first: 1) {
              nodes {
                id
                name
              }
            }
          }
          purchaseA {
            id
            rating
            completionStatus
          }
          purchaseB {
            id
            rating
            completionStatus
          }
          ratingDifference
        }
      }
    }
  }
`;

// One user's games the other doesn't own, for the "Only…" tabs. Only one side
// is ever shown at a time, so the other is skipped.
export const GET_COMPARISON_ONLY = gql`
  query GetComparisonOnly(
    $userASlug: String!
    $userBSlug: String!
    $sideA: Boolean!
    $first: Int!
    $after: String
    $sortBy: GamePurchaseSort
    $search: String
  ) {
    libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
      onlyA(first: $first, after: $after, sortBy: $sortBy, search: $search) @include(if: $sideA) {
        ...ComparisonOnlyFields
      }
      onlyB(first: $first, after: $after, sortBy: $sortBy, search: $search) @skip(if: $sideA) {
        ...ComparisonOnlyFields
      }
    }
  }

  fragment ComparisonOnlyFields on GamePurchaseConnection {
    totalCount
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      ...LibraryGamePurchaseFields
    }
  }
  ${LIBRARY_GAME_PURCHASE_FIELDS}
`;

// The "Compare with someone else" picker.
export const SEARCH_USERS_TO_COMPARE = gql`
  query SearchUsersToCompare($query: String!) {
    userSearch(query: $query, first: 8) {
      nodes {
        ...ComparisonUserFields
        privacy
        banned
      }
    }
  }
  ${COMPARISON_USER_FIELDS}
`;
