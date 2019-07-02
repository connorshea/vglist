# typed: strict
class GamePurchasePlatform < ApplicationRecord
  belongs_to :game_purchase
  belongs_to :platform

  validates :game_purchase_id,
    uniqueness: { scope: :platform_id }
end
