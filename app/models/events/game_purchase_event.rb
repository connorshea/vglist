# typed: strict
module Events
  class GamePurchaseEvent < ApplicationRecord
    self.table_name = 'events_game_purchase_events'

    belongs_to :eventable, class_name: 'GamePurchase'
    belongs_to :user, inverse_of: :game_purchase_events

    validates :event_category, presence: true

    enum event_category: {
      add_to_library: 0,
      change_completion_status: 1
    }
  end
end
