# typed: false

module GlobalSearchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    extend T::Sig

    sig { params(fields: Symbol).void }
    def global_searchable(*fields)
      multisearchable against: fields
    end
  end
end
