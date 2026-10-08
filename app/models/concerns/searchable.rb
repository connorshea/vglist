# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    # Defines a `search` scope. Trigram matching catches typos the way
    # `globalSearch` (multisearch) does, and ranking by both features puts
    # the closer name first: "Ratatouille" above "Ratatouille: Food Frenzy",
    # which full-text search alone can rank as a tie.
    def searchable(*fields, tsearch: { prefix: true })
      pg_search_scope :search,
        against: fields,
        using: {
          tsearch: tsearch,
          trigram: {}
        },
        ranked_by: ':tsearch + :trigram'
    end
  end
end
