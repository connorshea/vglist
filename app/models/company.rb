class Company < ApplicationRecord
  include PgSearch

  has_many :game_developers
  has_many :developed_games, through: :game_developers, source: :game

  has_many :game_publishers
  has_many :published_games, through: :game_publishers, source: :game

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
