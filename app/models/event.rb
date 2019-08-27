# typed: strict
class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true
  belongs_to :user, inverse_of: :events

  scope :game_purchases, -> { where(eventable_type: 'GamePurchase') }
  scope :favorite_games, -> { where(eventable_type: 'FavoriteGame') }
  scope :recently_created, -> { order("created_at desc") }

  validates :event_category, presence: true

  enum event_category: {
    add_to_library: 0,
    change_completion_status: 1,
    favorite_game: 2,
    new_user: 3
  }
end
