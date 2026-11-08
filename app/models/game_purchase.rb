# frozen_string_literal: true

class GamePurchase < ApplicationRecord
  # The comments and replay_count columns are NOT NULL, but clients clear a
  # field by sending null, so store their empty values instead.
  before_validation do
    self.comments = '' if comments.nil?
    self.replay_count = 0 if replay_count.nil?
  end

  # The largest value hours_played's numeric(10,1) column can hold.
  MAX_HOURS_PLAYED = 999_999_999.9

  after_create :game_purchase_create
  after_update :game_purchase_update
  after_destroy :game_purchase_destroy

  # Keeps games.game_purchases_count up to date for Game.most_owners.
  belongs_to :game, counter_cache: true
  belongs_to :user

  has_many :game_purchase_platforms
  has_many :platforms, through: :game_purchase_platforms, source: :platform
  has_many :game_purchase_stores
  has_many :stores, through: :game_purchase_stores, source: :store

  has_many :game_purchase_events, foreign_key: :eventable_id, inverse_of: :eventable, class_name: 'Events::GamePurchaseEvent', dependent: :destroy

  enum :completion_status, {
    unplayed: 0,
    in_progress: 1,
    dropped: 2,
    completed: 3,
    fully_completed: 4,
    not_applicable: 5,
    paused: 6
  }

  # The completion statuses that count as 'the user finished this game', used
  # for the completion stats on a user's profile.
  COMPLETED_STATUSES = [:completed, :fully_completed].freeze

  # Every sort below breaks ties on `id`, so that the ordering is total.
  # Cursor-based pagination walks the relation by offset, so a partial ordering
  # would let rows repeat or vanish between pages.
  scope :by_game_name, -> { joins(:game).order('games.name asc', :id) }
  # Postgres sorts NULLs first when sorting descending, but a game with no
  # rating (or no hours logged) belongs at the bottom of these lists.
  scope :highest_rating, -> { order(Arel.sql('rating desc nulls last'), :id) }
  scope :most_hours_played, -> { order(Arel.sql('hours_played desc nulls last'), :id) }

  # Find the games in a library whose name contains the given string.
  scope :with_game_name_matching, ->(query) {
    joins(:game).where('games.name ILIKE ?', "%#{sanitize_sql_like(query)}%")
  }

  # Find the games in a library that the user owns on any of the given
  # platforms (or from any of the given stores). These filter with a subquery
  # rather than a join so that a game owned on two of the platforms is only
  # returned once.
  scope :on_any_platform, ->(platform_ids) {
    where(id: GamePurchasePlatform.where(platform_id: platform_ids).select(:game_purchase_id))
  }
  scope :from_any_store, ->(store_ids) {
    where(id: GamePurchaseStore.where(store_id: store_ids).select(:game_purchase_id))
  }

  # Find the games in a library that the user rated within the given range,
  # inclusive. Either bound can be nil to leave that end open. Unrated games
  # never match, since a rating filter is asking for rated games.
  scope :rated_between, ->(min, max) {
    where(rating: (min || 0)..(max || 100))
  }

  validates :comments,
    length: { maximum: 2000 }

  validates :game_id,
    uniqueness: {
      scope: :user_id,
      message: 'is already in your library'
    }

  validates :rating,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      only_integer: true,
      allow_nil: true
    }

  validates :hours_played,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: MAX_HOURS_PLAYED,
      allow_nil: true
    }

  validates :replay_count,
    numericality: {
      greater_than_or_equal_to: 0,
      allow_nil: true
    }

  validate :start_date_before_completion_date

  private

  def start_date_before_completion_date
    return if start_date.nil? || completion_date.nil?

    return unless start_date > completion_date

    errors.add(:start_date, "can't be after completion date")
  end

  def game_purchase_create
    Events::GamePurchaseEvent.create!(
      eventable_id: id,
      user_id: user.id,
      event_category: :add_to_library
    )

    update_average_rating
  end

  def game_purchase_update
    update_average_rating

    return unless saved_changes.key?('completion_status')

    Events::GamePurchaseEvent.create!(
      eventable_id: id,
      user_id: user.id,
      event_category: :change_completion_status,
      # We don't need the updated_at value
      differences: saved_changes.except!(:updated_at)
    )
  end

  def game_purchase_destroy
    update_average_rating
  end

  # If there aren't any game purchases for a given game, it'll return nil so
  # avg_rating should be set to nil.
  def update_average_rating
    average = GamePurchase.where(game_id: game_id).average(:rating)
    average.nil? ? game.update(avg_rating: nil) : game.update(avg_rating: average.round(1))
  end
end
