class Series < ApplicationRecord
  include PgSearch

  has_many :game_series
  has_many :games, through: :game_series, source: :game

  validates :name,
    presence: true,
    length: { maximum: 120 }

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
