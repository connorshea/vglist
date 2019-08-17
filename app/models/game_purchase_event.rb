# typed: true
class GamePurchaseEvent < ApplicationRecord
  belongs_to :user
  belongs_to :game_purchase

  enum event_type: {
    add_to_library: 0,
    completion_status: 1
  }
end
