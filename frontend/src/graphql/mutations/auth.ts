import gql from "graphql-tag";

export const SIGN_IN = gql`
  mutation SignIn($email: String!, $password: String!) {
    signIn(email: $email, password: $password) {
      token
      userId
      username
      slug
      role
      errors
    }
  }
`;

export const SIGN_UP = gql`
  mutation SignUp(
    $username: String!
    $email: String!
    $password: String!
    $passwordConfirmation: String!
  ) {
    signUp(
      username: $username
      email: $email
      password: $password
      passwordConfirmation: $passwordConfirmation
    ) {
      message
      errors
    }
  }
`;

export const REQUEST_PASSWORD_RESET = gql`
  mutation RequestPasswordReset($email: String!) {
    requestPasswordReset(email: $email) {
      message
    }
  }
`;
