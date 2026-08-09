import gql from "graphql-tag";

export const GET_USER = gql`
  query GetUser($slug: String!) {
    user(slug: $slug) {
      id
      username
      bio
      slug
      role
      privacy
      createdAt
      banned
      avatarUrl(size: LARGE)
      isFollowed
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
      }
      followers {
        totalCount
      }
      following {
        totalCount
      }
      favoritedGames(first: 10) {
        nodes {
          id
          name
          coverUrl(size: SMALL)
        }
      }
    }
  }
`;

// The library is fetched separately from the rest of the profile so that
// changing a filter, the sort order, or the search term doesn't refetch the
// avatar, favorites, and library statistics along with it. Filtering, sorting,
// and counting all happen on the server, so they cover the user's whole
// library rather than the page of it that's been loaded.
export const GET_USER_LIBRARY = gql`
  query GetUserLibrary(
    $slug: String!
    $first: Int
    $after: String
    $completionStatus: GamePurchaseCompletionStatus
    $search: String
    $sortBy: GamePurchaseSort
  ) {
    user(slug: $slug) {
      id
      gamePurchases(
        first: $first
        after: $after
        completionStatus: $completionStatus
        search: $search
        sortBy: $sortBy
      ) {
        totalCount
        nodes {
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
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_USERS = gql`
  query GetUsers($first: Int, $after: String, $sortBy: UserSort) {
    users(first: $first, after: $after, sortBy: $sortBy) {
      nodes {
        id
        username
        slug
        avatarUrl(size: SMALL)
        role
        privacy
        banned
        createdAt
        gamePurchases {
          totalCount
        }
      }
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const GET_USER_FOLLOWERS = gql`
  query GetUserFollowers($slug: String!, $first: Int, $after: String) {
    user(slug: $slug) {
      id
      username
      followers(first: $first, after: $after) {
        totalCount
        nodes {
          id
          username
          slug
          avatarUrl(size: SMALL)
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_USER_FOLLOWING = gql`
  query GetUserFollowing($slug: String!, $first: Int, $after: String) {
    user(slug: $slug) {
      id
      username
      following(first: $first, after: $after) {
        totalCount
        nodes {
          id
          username
          slug
          avatarUrl(size: SMALL)
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_USER_ACTIVITY = gql`
  query GetUserActivity($slug: String!, $first: Int, $after: String) {
    user(slug: $slug) {
      id
      username
      slug
      activity(first: $first, after: $after) {
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
          eventable {
            ... on GamePurchase {
              game {
                id
                name
                coverUrl(size: SMALL)
              }
              completionStatus
              rating
            }
            ... on FavoriteGame {
              game {
                id
                name
                coverUrl(size: SMALL)
              }
            }
            ... on Relationship {
              followed {
                id
                username
                slug
                avatarUrl(size: SMALL)
              }
            }
            ... on User {
              id
              username
              slug
              avatarUrl(size: SMALL)
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

export const GET_CURRENT_USER_PROFILE = gql`
  query GetCurrentUserProfile {
    currentUser {
      id
      bio
      privacy
      hideDaysPlayed
    }
  }
`;
