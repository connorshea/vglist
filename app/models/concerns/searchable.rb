# typed: false

module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    extend T::Sig

    sig { params(fields: Symbol).void }
    def searchable(*fields)
      pg_search_scope :search,
        against: fields,
        using: {
          tsearch: { prefix: true }
        }
    end
  end
end
