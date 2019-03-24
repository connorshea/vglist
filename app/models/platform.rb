class Platform < ApplicationRecord
  include PgSearch

  has_many :game_platforms
  has_many :games, through: :game_platforms, source: :game

  has_many :game_platform_purchases
  has_many :users, through: :game_platform_purchases, source: :user

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
