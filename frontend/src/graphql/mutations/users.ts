import gql from "graphql-tag";

export const FOLLOW_USER = gql`
  mutation FollowUser($userId: ID!) {
    followUser(userId: $userId) {
      user {
        id
        username
      }
    }
  }
`;

export const UNFOLLOW_USER = gql`
  mutation UnfollowUser($userId: ID!) {
    unfollowUser(userId: $userId) {
      user {
        id
        username
      }
    }
  }
`;

export const BAN_USER = gql`
  mutation BanUser($userId: ID!) {
    banUser(userId: $userId) {
      user {
        id
        banned
        role
      }
    }
  }
`;

export const UNBAN_USER = gql`
  mutation UnbanUser($userId: ID!) {
    unbanUser(userId: $userId) {
      user {
        id
        banned
      }
    }
  }
`;

export const UPDATE_USER_ROLE = gql`
  mutation UpdateUserRole($userId: ID!, $role: UserRole!) {
    updateUserRole(userId: $userId, role: $role) {
      user {
        id
        role
      }
    }
  }
`;

export const REMOVE_USER_AVATAR = gql`
  mutation RemoveUserAvatar($userId: ID!) {
    removeUserAvatar(userId: $userId) {
      user {
        id
        avatarUrl
      }
    }
  }
`;
