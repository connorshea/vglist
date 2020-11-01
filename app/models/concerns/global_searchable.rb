# typed: false

module GlobalSearchable
  extend ActiveSupport::Concern
  include PgSearch::Model

  class_methods do
    def global_searchable(*fields)
      multisearchable against: fields
    end
  end
end
