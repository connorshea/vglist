# typed: true
class GamePurchaseEvent < ApplicationRecord
  belongs_to :user
  belongs_to :game_purchase

  validates :event_type, presence: true

  enum event_type: {
    add_to_library: 0,
    change_completion_status: 1
  }
end
