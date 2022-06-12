# typed: strict
class GamePurchase < ApplicationRecord
  after_create :game_purchase_create
  after_update :game_purchase_update
  after_destroy :game_purchase_destroy

  belongs_to :game
  belongs_to :user

  has_many :game_purchase_platforms
  has_many :platforms, through: :game_purchase_platforms, source: :platform
  has_many :game_purchase_stores
  has_many :stores, through: :game_purchase_stores, source: :store

  # Old events
  has_many :events, as: :eventable, dependent: :destroy
  # New events
  has_many :game_purchase_events, foreign_key: :eventable_id, inverse_of: :eventable, class_name: 'Events::GamePurchaseEvent', dependent: :destroy

  enum completion_status: {
    unplayed: 0,
    in_progress: 1,
    dropped: 2,
    completed: 3,
    fully_completed: 4,
    not_applicable: 5,
    paused: 6
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
      allow_nil: true
    }

  validates :replay_count,
    numericality: {
      greater_than_or_equal_to: 0,
      allow_nil: true
    }

  private

  sig { void }
  def game_purchase_create
    Events::GamePurchaseEvent.create!(
      eventable_id: id,
      user_id: user.id,
      event_category: :add_to_library
    )

    update_average_rating
  end

  sig { void }
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

  sig { void }
  def game_purchase_destroy
    update_average_rating
  end

  # If there aren't any game purchases for a given game, it'll return nil so
  # avg_rating should be set to nil.
  sig { void }
  def update_average_rating
    average = GamePurchase.where(game_id: game_id).average(:rating)
    average.nil? ? game.update(avg_rating: nil) : game.update(avg_rating: average.round(1))
  end
end
