# typed: true
class Types::SearchResultUnion < Types::BaseUnion
  description "The various possible types of search result."
  possible_types Types::SearchResults::UserSearchResultType,
                 Types::SearchResults::GameSearchResultType,
                 Types::SearchResults::GenreSearchResultType,
                 Types::SearchResults::EngineSearchResultType,
                 Types::SearchResults::PlatformSearchResultType,
                 Types::SearchResults::CompanySearchResultType,
                 Types::SearchResults::SeriesSearchResultType

  def self.resolve_type(object, _context)
    case object.searchable_type
    when 'User'
      Types::SearchResults::UserSearchResultType
    when 'Game'
      Types::SearchResults::GameSearchResultType
    when 'Genre'
      Types::SearchResults::GenreSearchResultType
    when 'Engine'
      Types::SearchResults::EngineSearchResultType
    when 'Platform'
      Types::SearchResults::PlatformSearchResultType
    when 'Company'
      Types::SearchResults::CompanySearchResultType
    when 'Series'
      Types::SearchResults::SeriesSearchResultType
    end
  end
end
