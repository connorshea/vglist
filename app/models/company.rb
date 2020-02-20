# typed: strong
class Company < ApplicationRecord
  include PgSearch::Model

  has_many :game_developers
  has_many :developed_games, through: :game_developers, source: :game

  has_many :game_publishers
  has_many :published_games, through: :game_publishers, source: :game

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

  # Include companies in global search.
  multisearchable against: [:name]

  # Search scope specific to companies.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
