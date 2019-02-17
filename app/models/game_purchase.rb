class GamePurchase < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :comment,
    length: { maximum: 500 }

  validates :game_id,
    uniqueness: { scope: :user_id }
end
