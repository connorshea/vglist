class Engine < ApplicationRecord
  include PgSearch

  has_many :game_engines
  has_many :games, through: :game_engines, source: :game

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

  # Include engines in global search.
  multisearchable against: [:name]

  # Search scope specific to engines.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
