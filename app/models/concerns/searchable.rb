# typed: false

module Searchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    extend T::Sig

    sig { params(fields: Symbol, tsearch: T::Hash[T.untyped, T.untyped]).void }
    def searchable(*fields, tsearch: { prefix: true })
      pg_search_scope :search,
        against: fields,
        using: {
          tsearch: tsearch
        }
    end
  end
end
