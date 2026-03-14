import gql from 'graphql-tag'

export const FOLLOW_USER = gql`
  mutation FollowUser($userId: ID!) {
    followUser(userId: $userId) {
      user { id username }
    }
  }
`

export const UNFOLLOW_USER = gql`
  mutation UnfollowUser($userId: ID!) {
    unfollowUser(userId: $userId) {
      user { id username }
    }
  }
`

export const UPDATE_USER = gql`
  mutation UpdateUser(
    $bio: String
    $privacy: UserPrivacy
    $hideDaysPlayed: Boolean
  ) {
    updateUser(
      bio: $bio
      privacy: $privacy
      hideDaysPlayed: $hideDaysPlayed
    ) {
      user {
        id
        bio
        privacy
        hideDaysPlayed
      }
      errors
    }
  }
`

export const RESET_API_TOKEN = gql`
  mutation ResetApiToken {
    resetApiToken {
      apiToken
      errors
    }
  }
`

export const EXPORT_LIBRARY = gql`
  mutation ExportLibrary {
    exportLibrary {
      libraryJson
      errors
    }
  }
`
