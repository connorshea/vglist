# typed: true
class Game < ApplicationRecord
  include PgSearch::Model

  has_many :game_purchases, dependent: :destroy
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

  has_many :steam_app_ids, dependent: :destroy
  accepts_nested_attributes_for :steam_app_ids, allow_destroy: true

  has_many :favorites,
    class_name: 'FavoriteGame',
    inverse_of: :user,
    dependent: :destroy

  belongs_to :series, optional: true

  has_one_attached :cover

  scope :newest, -> { order("created_at desc") }
  scope :oldest, -> { order("created_at asc") }
  scope :recently_updated, -> { order("updated_at desc") }
  scope :least_recently_updated, -> { order("updated_at asc") }
  # Sort by average rating.
  # Must have at least 5 owners w/ ratings to be included.
  scope :highest_avg_rating, -> {
    joins(:game_purchases)
      .where.not('game_purchases.rating': nil)
      .group('games.id')
      .having("count(game_purchases.id) >= ?", 5)
      .order("avg_rating desc")
  }
  # Sort by most favorites.
  scope :most_favorites, -> {
    left_joins(:favorites)
      .group(:id)
      .order(Arel.sql('count(favorite_games.game_id) desc'))
  }
  # Sort by most owners.
  scope :most_owners, -> {
    left_joins(:game_purchases)
      .group(:id)
      .order(Arel.sql('count(game_purchases.game_id) desc'))
  }
  # Sort by recently released.
  scope :recently_released, -> {
    where("release_date < ?", 1.day.from_now).order("release_date desc")
  }

  # Find games available on a given platform.
  scope :on_platform, ->(platform_id) {
    joins(:game_platforms).where(game_platforms: { platform_id: platform_id })
  }
  # Find games released in a given year.
  scope :by_year, ->(year) {
    where('extract(year from release_date) = ?', year)
  }

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :cover,
    attached: false,
    content_type: ['image/png', 'image/jpg', 'image/jpeg'],
    size: { less_than: 4.megabytes }

  validates :avg_rating,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      allow_nil: true
    }

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

  validates :mobygames_id,
    uniqueness: true,
    allow_nil: true,
    format: %r{\A[a-z\-_0-9]+/?[a-z\-_0-9]+\z},
    # Allow up to 300 characters just in case there's some game with an incredibly long name.
    length: { maximum: 300 }

  validates :giantbomb_id,
    uniqueness: true,
    allow_nil: true,
    # Validate that it's in a format like 3030-1539.
    format: /\A\d{4}-\d+\z/,
    length: { maximum: 100 }

  validates :epic_games_store_id,
    uniqueness: true,
    allow_nil: true,
    format: /\A[a-zA-Z0-9_-]*\z/,
    # Allow up to 300 characters just in case there's some game with an incredibly long name.
    length: { maximum: 300 }

  validates :gog_id,
    allow_nil: true,
    format: /\A[a-z0-9_]+\z/,
    # Allow up to 300 characters just in case there's some game with an incredibly long name.
    length: { maximum: 300 }

  validate :wikidata_id_not_blocklisted

  # Include games in global search.
  multisearchable against: [:name]

  # Search scope specific to games.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { normalization: 2 }
    }

  protected

  # Prevent the game from using a Wikidata ID which has been blocklisted.
  def wikidata_id_not_blocklisted
    return unless wikidata_id.present? && WikidataBlocklist.pluck(:wikidata_id).include?(wikidata_id)

    errors.add(:wikidata_id, "is blocklisted")
  end
end
