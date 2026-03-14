// These mutations are not yet in the GraphQL schema and are excluded from
// codegen. Types for these are maintained manually in types/graphql.ts.
import gql from 'graphql-tag'

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
