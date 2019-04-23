class Game < ApplicationRecord
  include PgSearch

  has_many :game_purchases
  has_many :purchasers, through: :game_purchases, source: :user

  has_many :game_developers
  has_many :developers, through: :game_developers, source: :company

  has_many :game_publishers
  has_many :publishers, through: :game_publishers, source: :company

  has_many :game_platforms
  has_many :platforms, through: :game_platforms, source: :platform

  has_many :game_genres
  has_many :genres, through: :game_genres, source: :genre

  has_many :game_engines
  has_many :engines, through: :game_engines, source: :engine

  has_many :favorites, as: :favoritable, dependent: :destroy

  belongs_to :series, optional: true

  has_one_attached :cover

  scope :newest, -> { order("created_at desc") }
  scope :oldest, -> { order("created_at asc") }
  scope :recently_updated, -> { order("updated_at desc") }
  scope :least_recently_updated, -> { order("updated_at asc") }
  # Have to include the check for NULL because otherwise games that haven't been favorited won't be included.
  # Also filter down to only favorites on games.
  scope :most_favorites, -> {
    left_joins(:favorites)
      .where("favorites.favoritable_type = 'Game' OR favorites.favoritable_type IS NULL")
      .group(:id)
      .order(Arel.sql('count(favorites.favoritable_id) desc'))
  }
  scope :most_owners, -> {
    left_joins(:game_purchases)
      .group(:id)
      .order(Arel.sql('count(game_purchases.game_id) desc'))
  }

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }

  validates :cover,
    attached: false,
    content_type: ['image/png', 'image/jpg', 'image/jpeg'],
    size: { less_than: 4.megabytes }

  validates :wikidata_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  validates :pcgamingwiki_id,
    uniqueness: true,
    allow_nil: true,
    # Validate the format with a simple regex that checks to make sure there
    # aren't any illegal characters (e.g. <, >, [, ], #, |, etc.)
    format: /\A[^<>\[\]#\s\\|]+\z/,
    # Allow up to 300 characters just in case there's some game with an incredibly long name.
    length: { maximum: 300 }

  validates :steam_app_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  # Include games in global search.
  multisearchable against: [:name]

  # Search scope specific to games.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
