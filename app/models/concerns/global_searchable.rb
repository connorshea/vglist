# typed: false
module GlobalSearchable
  extend ActiveSupport::Concern
  extend T::Helpers
  include PgSearch::Model

  module ClassMethods
    extend T::Sig

    sig { params(fields: Symbol).void }
    def global_searchable(*fields)
      multisearchable against: fields
    end
  end

  mixes_in_class_methods(ClassMethods)
end
