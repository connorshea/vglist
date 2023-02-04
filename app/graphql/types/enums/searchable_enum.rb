# typed: strict
module Types::Enums
  class SearchableEnum < Types::BaseEnum
    description "The types of records that can be returned as a `SearchResult`."

    value "COMPANY", value: 'Company', description: 'Self-explanatory.'
    value "ENGINE", value: 'Engine', description: 'Self-explanatory.'
    value "GAME", value: 'Game', description: 'Self-explanatory.'
    value "GENRE", value: 'Genre', description: 'Self-explanatory.'
    value "PLATFORM", value: 'Platform', description: 'Self-explanatory.'
    value "SERIES", value: 'Series', description: 'Self-explanatory.'
    value "USER", value: 'User', description: 'Self-explanatory.'
  end
end
