class GamePurchase < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :comment,
    length: { maximum: 500 }

  validates :game_id,
    uniqueness: { scope: :user_id }

  validates :score,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      only_integer: true,
      allow_nil: true
    }
end
