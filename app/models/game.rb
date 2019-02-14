class Game < ApplicationRecord
  include PgSearch

  has_many :releases
  has_many :platforms, through: :releases
  has_many :game_genres
  has_many :genres, through: :game_genres, source: :genre
  has_many :game_engines
  has_many :engines, through: :game_engines, source: :engine

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
