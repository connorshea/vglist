class GamePurchaseEvent < ApplicationRecord
  belongs_to :user
  belongs_to :game_purchase
end
