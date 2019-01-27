class Genre < ApplicationRecord
  include PgSearch

  has_many :game_genres
  has_many :games, through: :game_genres, source: :game

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
