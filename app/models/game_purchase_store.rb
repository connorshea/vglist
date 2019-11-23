# typed: strong
class GamePurchaseStore < ApplicationRecord
  belongs_to :game_purchase
  belongs_to :store

  validates :game_purchase_id,
    uniqueness: { scope: :store_id }
end
