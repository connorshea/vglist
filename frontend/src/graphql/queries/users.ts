import gql from "graphql-tag";

export const GET_CURRENT_USER = gql`
  query GetCurrentUser {
    currentUser {
      id
      username
      bio
      slug
      role
      privacy
      avatarUrl(size: SMALL)
      hideDaysPlayed
    }
  }
`;

export const GET_USER = gql`
  query GetUser($id: ID!) {
    user(id: $id) {
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
        nodes {
          id
          username
          slug
          avatarUrl(size: SMALL)
        }
      }
      following {
        totalCount
        nodes {
          id
          username
          slug
          avatarUrl(size: SMALL)
        }
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
  query GetUsers($first: Int, $after: String) {
    users(first: $first, after: $after) {
      nodes {
        id
        username
        slug
        avatarUrl(size: SMALL)
        gamePurchases {
          totalCount
        }
      }
      pageInfo {
        hasNextPage
        endCursor
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

export const SEARCH_USERS = gql`
  query SearchUsers($query: String!) {
    userSearch(query: $query) {
      nodes {
        id
        username
        slug
        avatarUrl(size: SMALL)
      }
    }
  }
`;
