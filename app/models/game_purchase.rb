class GamePurchase < ApplicationRecord
  belongs_to :game
  belongs_to :user

  has_many :game_purchase_platforms
  has_many :platforms, through: :game_purchase_platforms, source: :platform

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
    length: { maximum: 500 }

  validates :game_id,
    uniqueness: { scope: :user_id }

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
end
