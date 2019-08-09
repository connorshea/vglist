# typed: strict
class Platform < ApplicationRecord
  include PgSearch::Model

  has_many :game_platforms
  has_many :games, through: :game_platforms, source: :game

  has_many :game_purchase_platforms
  has_many :game_purchases, through: :game_purchase_platforms, source: :game_purchase

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }

  validates :wikidata_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  # Include platforms in global search.
  multisearchable against: [:name]

  # Search scope specific to platforms.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
