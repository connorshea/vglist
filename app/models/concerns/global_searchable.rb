module GlobalSearchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  module ClassMethods
    def global_searchable(*fields)
      multisearchable against: fields
    end
  end
end
