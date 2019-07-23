class Genre < ApplicationRecord
  include PgSearch::Model

  has_many :game_genres
  has_many :games, through: :game_genres, source: :game

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

  # Include genres in global search.
  multisearchable against: [:name]

  # Search scope specific to genres.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
