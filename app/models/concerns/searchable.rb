module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    def searchable(*fields, tsearch: { prefix: true })
      pg_search_scope :search,
        against: fields,
        using: {
          tsearch: tsearch
        }
    end
  end
end
