import gql from "graphql-tag";

export const UPDATE_USER = gql`
  mutation UpdateUser($bio: String, $privacy: UserPrivacy, $hideDaysPlayed: Boolean) {
    updateUser(bio: $bio, privacy: $privacy, hideDaysPlayed: $hideDaysPlayed) {
      user {
        id
        bio
        privacy
        hideDaysPlayed
      }
      errors
    }
  }
`;

export const EXPORT_LIBRARY = gql`
  mutation ExportLibrary {
    exportLibrary {
      libraryJson
      errors
    }
  }
`;

export const DELETE_USER = gql`
  mutation DeleteUser($userId: ID!) {
    deleteUser(userId: $userId) {
      deleted
    }
  }
`;

export const RESET_USER_LIBRARY = gql`
  mutation ResetUserLibrary($userId: ID!) {
    resetUserLibrary(userId: $userId) {
      deleted
    }
  }
`;

export const UPDATE_EMAIL = gql`
  mutation UpdateEmail($newEmail: String!, $currentPassword: String!) {
    updateEmail(newEmail: $newEmail, currentPassword: $currentPassword) {
      user {
        id
      }
      errors
    }
  }
`;

export const UPDATE_PASSWORD = gql`
  mutation UpdatePassword($currentPassword: String!, $newPassword: String!, $newPasswordConfirmation: String!) {
    updatePassword(
      currentPassword: $currentPassword
      newPassword: $newPassword
      newPasswordConfirmation: $newPasswordConfirmation
    ) {
      user {
        id
      }
      errors
    }
  }
`;

export const CONNECT_STEAM = gql`
  mutation ConnectSteam($userId: ID!, $steamUsername: String!) {
    connectSteam(userId: $userId, steamUsername: $steamUsername) {
      connected
    }
  }
`;

export const DISCONNECT_STEAM = gql`
  mutation DisconnectSteam($userId: ID!) {
    disconnectSteam(userId: $userId) {
      disconnected
    }
  }
`;

export const IMPORT_STEAM_LIBRARY = gql`
  mutation ImportSteamLibrary($userId: ID!, $updateHours: Boolean) {
    importSteamLibrary(userId: $userId, updateHours: $updateHours) {
      addedGamesCount
      updatedGamesCount
      unmatchedCount
      addedGames {
        id
        name
        coverUrl(size: SMALL)
      }
      updatedGames {
        id
        name
        coverUrl(size: SMALL)
      }
      unmatchedGames {
        name
        steamAppId
      }
    }
  }
`;
