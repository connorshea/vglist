import gql from "graphql-tag";

// Search-as-you-type queries for the game form's association fields.

export const SEARCH_PLATFORMS_FOR_GAME_FORM = gql`
  query SearchPlatformsForGameForm($query: String!) {
    platformSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_COMPANIES_FOR_GAME_FORM = gql`
  query SearchCompaniesForGameForm($query: String!) {
    companySearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_GENRES_FOR_GAME_FORM = gql`
  query SearchGenresForGameForm($query: String!) {
    genreSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_ENGINES_FOR_GAME_FORM = gql`
  query SearchEnginesForGameForm($query: String!) {
    engineSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;

export const SEARCH_SERIES_FOR_GAME_FORM = gql`
  query SearchSeriesForGameForm($query: String!) {
    seriesSearch(query: $query, first: 10) {
      nodes {
        id
        name
      }
    }
  }
`;
