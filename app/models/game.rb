class Game < ApplicationRecord
  include PgSearch

  # Update the earliest release date before validating.
  before_validation :update_earliest_release_date, if: :release_dates?

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

  belongs_to :series, optional: true

  has_one_attached :cover

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }

  validates :cover,
    attached: false,
    content_type: ['image/png', 'image/jpg', 'image/jpeg'],
    size: { less_than: 4.megabytes }

  # Search scope specific to games.
  # Only require earliest_release_date if release_dates has data.
  validates :earliest_release_date,
    presence: { if: :release_dates? }

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

  # Include games in global search.
  multisearchable against: [:name]

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }

  private

  # Get the earliest release date from the release_dates attribute.
  def update_earliest_release_date
    self.earliest_release_date = release_dates.map{ |x| x['release_date'] }.min
  end
end
