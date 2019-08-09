# typed: strict
class Series < ApplicationRecord
  include PgSearch::Model

  has_many :games

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :wikidata_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  # Include series in global search.
  multisearchable against: [:name]

  # Search scope specific to series.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
