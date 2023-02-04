# typed: strict
class Game < ApplicationRecord
  include GlobalSearchable
  include Searchable

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

  has_many :favoriters,
    through: :favorites,
    source: :user

  belongs_to :series, optional: true

  has_one_attached :cover

  # Track changes to the record, but ignore changes to the average rating.
  has_paper_trail ignore: [:avg_rating, :updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::GameVersion'
                  }

  # Only use one of the pre-set sizes for these images.
  COVER_SIZES = T.let(
    {
      small: [200, 300],
      medium: [300, 500],
      large: [500, 800]
    },
    T::Hash[Symbol, [Integer, Integer]]
  )

  scope :newest, -> { order("created_at desc") }
  scope :oldest, -> { order("created_at asc") }
  scope :recently_updated, -> { order("updated_at desc") }
  scope :least_recently_updated, -> { order("updated_at asc") }
  # Sort by average rating.
  # Must have at least 5 owners w/ ratings to be included.
  # Also check that the avg_rating column isn't nil to preven[t weirdness in
  # certain cases where the game record becomes invalid.
  scope :highest_avg_rating, -> {
    joins(:game_purchases)
      .where.not('game_purchases.rating': nil)
      .where.not('games.avg_rating': nil)
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

  # Find games in a given genre.
  scope :by_genre, ->(genre_id) {
    joins(:game_genres).where(game_genres: { genre_id: genre_id })
  }

  # Find games built with a given engine.
  scope :by_engine, ->(engine_id) {
    joins(:game_engines).where(game_engines: { engine_id: engine_id })
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
    content_type: ['image/png', 'image/jpeg'],
    size: { less_than: 4.megabytes }

  validates :avg_rating,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      allow_nil: true
    }

  validates :wikidata_id,
    uniqueness: true,
    allow_blank: true,
    numericality: {
      only_integer: true,
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
    format: %r{\A[a-z\-_0-9]+/?([a-z\-_0-9]+)?\z},
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

  validates :igdb_id,
    uniqueness: true,
    allow_nil: true,
    format: /\A[a-z0-9\-~]+\z/,
    # Allow up to 300 characters just in case there's some game with an incredibly long name.
    length: { maximum: 300 }

  validate :wikidata_id_not_blocklisted

  global_searchable :name
  searchable :name, tsearch: { normalization: 2 }

  # Generate a cover variant with a specific size, size must be a Symbol
  # matching one of the keys in `Game::COVER_SIZES`.
  sig do
    params(size: Symbol).returns(
      T.nilable(
        T.any(
          ActiveStorage::Variant,
          ActiveStorage::VariantWithRecord
        )
      )
    )
  end
  def sized_cover(size)
    width, height = COVER_SIZES[size]
    cover.variant(
      resize_to_limit: [width, height]
    )
  end

  protected

  # Prevent the game from using a Wikidata ID which has been blocklisted.
  sig { void }
  def wikidata_id_not_blocklisted
    return unless wikidata_id.present? && WikidataBlocklist.pluck(:wikidata_id).include?(wikidata_id)

    errors.add(:wikidata_id, "is blocklisted")
  end
end
