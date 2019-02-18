class Platform < ApplicationRecord
  include PgSearch

  has_many :game_platforms
  has_many :games, through: :game_platforms, source: :game

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
