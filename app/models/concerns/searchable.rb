# typed: false

module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  class_methods do
    def searchable(*fields)
      pg_search_scope :search,
        against: fields,
        using: {
          tsearch: { prefix: true }
        }
    end
  end
end
