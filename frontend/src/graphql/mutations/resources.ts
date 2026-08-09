import gql from "graphql-tag";

export const CREATE_PLATFORM = gql`
  mutation CreatePlatform($name: String!, $wikidataId: ID!) {
    createPlatform(name: $name, wikidataId: $wikidataId) {
      platform {
        id
        name
      }
    }
  }
`;

export const UPDATE_PLATFORM = gql`
  mutation UpdatePlatform($platformId: ID!, $name: String, $wikidataId: ID) {
    updatePlatform(platformId: $platformId, name: $name, wikidataId: $wikidataId) {
      platform {
        id
        name
      }
    }
  }
`;

export const DELETE_PLATFORM = gql`
  mutation DeletePlatform($platformId: ID!) {
    deletePlatform(platformId: $platformId) {
      deleted
    }
  }
`;

export const CREATE_COMPANY = gql`
  mutation CreateCompany($name: String!, $wikidataId: ID!) {
    createCompany(name: $name, wikidataId: $wikidataId) {
      company {
        id
        name
      }
    }
  }
`;

export const UPDATE_COMPANY = gql`
  mutation UpdateCompany($companyId: ID!, $name: String, $wikidataId: ID) {
    updateCompany(companyId: $companyId, name: $name, wikidataId: $wikidataId) {
      company {
        id
        name
      }
    }
  }
`;

export const DELETE_COMPANY = gql`
  mutation DeleteCompany($companyId: ID!) {
    deleteCompany(companyId: $companyId) {
      deleted
    }
  }
`;

export const CREATE_ENGINE = gql`
  mutation CreateEngine($name: String!, $wikidataId: ID!) {
    createEngine(name: $name, wikidataId: $wikidataId) {
      engine {
        id
        name
      }
    }
  }
`;

export const UPDATE_ENGINE = gql`
  mutation UpdateEngine($engineId: ID!, $name: String, $wikidataId: ID) {
    updateEngine(engineId: $engineId, name: $name, wikidataId: $wikidataId) {
      engine {
        id
        name
      }
    }
  }
`;

export const DELETE_ENGINE = gql`
  mutation DeleteEngine($engineId: ID!) {
    deleteEngine(engineId: $engineId) {
      deleted
    }
  }
`;

export const CREATE_GENRE = gql`
  mutation CreateGenre($name: String!, $wikidataId: ID!) {
    createGenre(name: $name, wikidataId: $wikidataId) {
      genre {
        id
        name
      }
    }
  }
`;

export const UPDATE_GENRE = gql`
  mutation UpdateGenre($genreId: ID!, $name: String, $wikidataId: ID) {
    updateGenre(genreId: $genreId, name: $name, wikidataId: $wikidataId) {
      genre {
        id
        name
      }
    }
  }
`;

export const DELETE_GENRE = gql`
  mutation DeleteGenre($genreId: ID!) {
    deleteGenre(genreId: $genreId) {
      deleted
    }
  }
`;

export const CREATE_SERIES = gql`
  mutation CreateSeries($name: String!, $wikidataId: ID!) {
    createSeries(name: $name, wikidataId: $wikidataId) {
      series {
        id
        name
      }
    }
  }
`;

export const UPDATE_SERIES = gql`
  mutation UpdateSeries($seriesId: ID!, $name: String, $wikidataId: ID) {
    updateSeries(seriesId: $seriesId, name: $name, wikidataId: $wikidataId) {
      series {
        id
        name
      }
    }
  }
`;

export const DELETE_SERIES = gql`
  mutation DeleteSeries($seriesId: ID!) {
    deleteSeries(seriesId: $seriesId) {
      deleted
    }
  }
`;

export const CREATE_STORE = gql`
  mutation CreateStore($name: String!) {
    createStore(name: $name) {
      store {
        id
        name
      }
    }
  }
`;

export const UPDATE_STORE = gql`
  mutation UpdateStore($storeId: ID!, $name: String) {
    updateStore(storeId: $storeId, name: $name) {
      store {
        id
        name
      }
    }
  }
`;

export const DELETE_STORE = gql`
  mutation DeleteStore($storeId: ID!) {
    deleteStore(storeId: $storeId) {
      deleted
    }
  }
`;
