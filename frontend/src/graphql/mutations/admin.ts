import gql from "graphql-tag";

export const ADD_TO_STEAM_BLOCKLIST = gql`
  mutation AddToSteamBlocklist($name: String!, $steamAppId: Int!) {
    addToSteamBlocklist(name: $name, steamAppId: $steamAppId) {
      steamBlocklistEntry {
        id
        name
        steamAppId
      }
    }
  }
`;

export const REMOVE_FROM_STEAM_BLOCKLIST = gql`
  mutation RemoveFromSteamBlocklist($steamBlocklistEntryId: ID!) {
    removeFromSteamBlocklist(steamBlocklistEntryId: $steamBlocklistEntryId) {
      deleted
    }
  }
`;

export const ADD_TO_WIKIDATA_BLOCKLIST = gql`
  mutation AddToWikidataBlocklist($name: String!, $wikidataId: Int!) {
    addToWikidataBlocklist(name: $name, wikidataId: $wikidataId) {
      wikidataBlocklistEntry {
        id
        name
        wikidataId
      }
    }
  }
`;

export const REMOVE_FROM_WIKIDATA_BLOCKLIST = gql`
  mutation RemoveFromWikidataBlocklist($wikidataBlocklistEntryId: ID!) {
    removeFromWikidataBlocklist(wikidataBlocklistEntryId: $wikidataBlocklistEntryId) {
      deleted
    }
  }
`;

export const REMOVE_FROM_UNMATCHED_GAMES = gql`
  mutation RemoveFromUnmatchedGames($externalServiceId: ID!, $externalServiceName: UnmatchedGameExternalService!) {
    removeFromUnmatchedGames(externalServiceId: $externalServiceId, externalServiceName: $externalServiceName) {
      deleted
    }
  }
`;

export const MERGE_GAMES = gql`
  mutation MergeGames($gameToKeepId: ID!, $gameToMergeId: ID!) {
    mergeGames(gameToKeepId: $gameToKeepId, gameToMergeId: $gameToMergeId) {
      game {
        id
        name
      }
    }
  }
`;
