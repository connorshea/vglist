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
      gamePurchases(first: 30) {
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
