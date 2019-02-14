class Engine < ApplicationRecord
  include PgSearch

  has_many :game_engines
  has_many :games, through: :game_engines, source: :game

  validates :name,
    presence: true,
    length: { maximum: 120 }

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
