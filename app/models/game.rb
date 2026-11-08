# frozen_string_literal: true

class Game < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_purchases, dependent: :destroy
  has_many :purchasers, through: :game_purchases, source: :user

  has_many :game_developers, dependent: :destroy
  has_many :developers, through: :game_developers, source: :company

  has_many :game_publishers, dependent: :destroy
  has_many :publishers, through: :game_publishers, source: :company

  has_many :game_platforms, dependent: :destroy
  has_many :platforms, through: :game_platforms, source: :platform

  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres, source: :genre

  has_many :game_engines, dependent: :destroy
  has_many :engines, through: :game_engines, source: :engine

  has_many :steam_app_ids, dependent: :destroy
  accepts_nested_attributes_for :steam_app_ids, allow_destroy: true

  has_many :favorites,
    class_name: 'FavoriteGame',
    inverse_of: :game,
    dependent: :destroy

  has_many :favoriters,
    through: :favorites,
    source: :user

  belongs_to :series, optional: true

  # Only use one of the pre-set sizes for these images.
  COVER_SIZES = {
    small: [200, 300],
    medium: [300, 500],
    large: [500, 800]
  }.freeze

  # `preprocessed: true` enqueues an ActiveStorage::TransformJob for each
  # variant as soon as a cover is attached, so the first page to show a new
  # cover doesn't have to download, resize, and upload it mid-request.
  has_one_attached :cover do |attachable|
    attachable.variant :small, resize_to_limit: COVER_SIZES[:small], preprocessed: true
    attachable.variant :medium, resize_to_limit: COVER_SIZES[:medium], preprocessed: true
    attachable.variant :large, resize_to_limit: COVER_SIZES[:large], preprocessed: true
  end

  # Use PaperTrail to track changes to the record.

  # Track changes to the record, but ignore changes to the average rating
  # and its count.
  has_paper_trail ignore: [:avg_rating, :ratings_count, :updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::GameVersion'
                  }

  # Every sort ends with `games.id`, so games that tie on the main key (say,
  # the many with no owners) keep the same order from one query to the next.
  # Without it, offset pagination repeats some games and skips others.
  scope :newest, -> { order(created_at: :desc, id: :desc) }
  scope :oldest, -> { order(created_at: :asc, id: :asc) }
  scope :recently_updated, -> { order(updated_at: :desc, id: :desc) }
  scope :least_recently_updated, -> { order(updated_at: :asc, id: :asc) }
  # Sort by average rating. Only games with at least 5 ratings are listed,
  # so a single rating can't put a game at the top. Reads the ratings_count
  # column (kept up to date with avg_rating) rather than counting every
  # game's ratings per query, and is backed by a partial index on
  # (avg_rating, id). Games with no avg_rating are skipped too, in case a
  # game record ends up invalid.
  scope :highest_avg_rating, -> {
    where(ratings_count: 5..)
      .where.not(avg_rating: nil)
      .order(avg_rating: :desc, id: :desc)
  }
  # Sort by most favorites.
  scope :most_favorites, -> {
    left_joins(:favorites)
      .group(:id)
      .order(Arel.sql('count(favorite_games.game_id) desc'), id: :desc)
  }
  # Sort by most owners. Reads the game_purchases_count counter cache, which
  # is indexed, rather than counting every game's library entries per query.
  scope :most_owners, -> { order(game_purchases_count: :desc, id: :desc) }
  # Sort by recently released.
  scope :recently_released, -> {
    where("release_date < ?", 1.day.from_now).order(release_date: :desc, id: :desc)
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

  # Find games released in or after a given year.
  scope :released_from_year, ->(year) {
    where(release_date: Date.new(year, 1, 1)..)
  }

  # Find games released in or before a given year.
  scope :released_to_year, ->(year) {
    where(release_date: ...Date.new(year + 1, 1, 1))
  }

  validates :name,
    presence: true,
    length: { maximum: 120 }

  # Only validate a newly attached cover. For an existing one, the validators
  # fall back to the stored file, and spoofing protection downloads it from
  # storage on every save, even ones that don't touch the cover.
  validates :cover,
    attached: false,
    content_type: { in: ActiveStorage.variable_content_types, spoofing_protection: true },
    size: { less_than: 4.megabytes },
    if: -> { attachment_changes["cover"].present? }

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
    allow_blank: true,
    numericality: {
      only_integer: true,
      greater_than: 0
    }

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

  validate :wikidata_id_not_blocklisted, if: -> { wikidata_id.present? }

  global_searchable :name
  searchable :name, tsearch: { normalization: 2 }

  # The cover at a specific size, or the original cover if that size hasn't
  # been created yet (it's then created in the background, see ReadyVariant).
  # @param size [Symbol] One of the keys in `Game::COVER_SIZES`.
  # @return [ActiveStorage::VariantWithRecord, ActiveStorage::Attached::One, nil]
  #   Something that responds to `url`, or nil if there's no cover.
  def sized_cover(size)
    ReadyVariant.for(cover, size)
  end

  # Recalculate the average rating and how many ratings it's based on (which
  # Game.highest_avg_rating filters on) from the game's library entries.
  # With no ratings, the average is nil. Called after every library entry
  # change, and after a merge moves another game's entries onto this one.
  # @return [Boolean] Whether the game saved.
  def update_ratings
    count, average = game_purchases.where.not(rating: nil)
                                   .pick(Arel.sql('count(*)'), Arel.sql('avg(rating)'))
    update(avg_rating: average&.round(1), ratings_count: count)
  end

  protected

  # Prevent the game from using a Wikidata ID which has been blocklisted.
  def wikidata_id_not_blocklisted
    return unless WikidataBlocklist.exists?(wikidata_id: wikidata_id)

    errors.add(:wikidata_id, "is blocklisted")
  end
end
