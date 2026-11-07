import gql from "graphql-tag";

// Signing in with a passkey (anonymous).

export const PASSKEY_AUTHENTICATION_OPTIONS = gql`
  mutation PasskeyAuthenticationOptions {
    passkeyAuthenticationOptions {
      options
    }
  }
`;

export const SIGN_IN_WITH_PASSKEY = gql`
  mutation SignInWithPasskey($response: JSON!) {
    signInWithPasskey(response: $response) {
      token
      userId
      username
      slug
      role
      email
      avatarUrl
      errors
    }
  }
`;

// Managing the signed-in user's passkeys.

export const PASSKEY_REGISTRATION_OPTIONS = gql`
  mutation PasskeyRegistrationOptions {
    passkeyRegistrationOptions {
      options
      errors
    }
  }
`;

export const REGISTER_PASSKEY = gql`
  mutation RegisterPasskey($response: JSON!, $nickname: String) {
    registerPasskey(response: $response, nickname: $nickname) {
      passkey {
        id
        nickname
        backedUp
        lastUsedAt
        createdAt
      }
      errors
    }
  }
`;

export const RENAME_PASSKEY = gql`
  mutation RenamePasskey($id: ID!, $nickname: String!) {
    renamePasskey(id: $id, nickname: $nickname) {
      passkey {
        id
        nickname
      }
      errors
    }
  }
`;

export const DELETE_PASSKEY = gql`
  mutation DeletePasskey($id: ID!) {
    deletePasskey(id: $id) {
      deleted
    }
  }
`;
