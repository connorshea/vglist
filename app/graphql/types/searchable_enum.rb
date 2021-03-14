# typed: strict
module Types
  class SearchableEnum < Types::BaseEnum
    description "The types of records that can be returned as a `SearchResult`."

    value "COMPANY", value: 'Company'
    value "ENGINE", value: 'Engine'
    value "GAME", value: 'Game'
    value "GENRE", value: 'Genre'
    value "PLATFORM", value: 'Platform'
    value "SERIES", value: 'Series'
    value "USER", value: 'User'
  end
end
