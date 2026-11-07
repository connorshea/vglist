import gql from "graphql-tag";
import { LIBRARY_PLAYING_PURCHASE_FIELDS } from "@/graphql/queries/library";

// The header and tab bar shared by every page of a user's profile. The tabs'
// own content is fetched by each tab, so switching tabs doesn't refetch this.
export const GET_USER_PROFILE = gql`
  query GetUserProfile($slug: String!) {
    user(slug: $slug) {
      id
      username
      slug
      role
      privacy
      banned
      avatarUrl(size: LARGE)
      isFollowed
      hideDaysPlayed
      libraryStatistics {
        gamesCount
        totalHoursPlayed
        completionPercentage
        averageRating
      }
      favoritedGames {
        totalCount
      }
      followers {
        totalCount
      }
      following {
        totalCount
      }
    }
  }
`;

// The Overview tab: the user's bio, a few favorites, what they're playing, and
// their highest-rated games.
export const GET_USER_OVERVIEW = gql`
  query GetUserOverview($slug: String!, $favoritesCount: Int!, $playingCount: Int!, $topRatedCount: Int!) {
    user(slug: $slug) {
      id
      bio
      favoritedGames(first: $favoritesCount) {
        totalCount
        nodes {
          id
          name
          coverUrl(size: SMALL)
        }
      }
      playing: gamePurchases(first: $playingCount, completionStatus: IN_PROGRESS, sortBy: MOST_HOURS_PLAYED) {
        totalCount
        nodes {
          ...LibraryPlayingPurchaseFields
        }
      }
      topRated: gamePurchases(first: $topRatedCount, sortBy: HIGHEST_RATING) {
        totalCount
        nodes {
          ...LibraryGamePurchaseFields
        }
      }
    }
  }
  ${LIBRARY_PLAYING_PURCHASE_FIELDS}
`;

export const GET_USER_FAVORITES = gql`
  query GetUserFavorites($slug: String!, $first: Int, $after: String) {
    user(slug: $slug) {
      id
      favoritedGames(first: $first, after: $after) {
        totalCount
        nodes {
          id
          name
          coverUrl(size: SMALL)
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
          completionStatusChange {
            before
            after
          }
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
      username
      avatarUrl(size: LARGE)
      bio
      privacy
      hideDaysPlayed
    }
  }
`;

export const GET_CURRENT_USER_STEAM_ACCOUNT = gql`
  query GetCurrentUserSteamAccount {
    currentUser {
      id
      steamProfileUrl
    }
  }
`;

// Just the avatar for the navbar's user menu. SMALL is the 80px variant.
export const GET_CURRENT_USER_AVATAR = gql`
  query GetCurrentUserAvatar {
    currentUser {
      id
      avatarUrl(size: SMALL)
    }
  }
`;
