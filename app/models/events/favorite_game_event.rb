# typed: strict
module Events
  class FavoriteGameEvent < ApplicationRecord
    self.table_name = 'events_favorite_game_events'

    belongs_to :eventable, class_name: 'FavoriteGame'
    belongs_to :user, inverse_of: :favorite_game_events

    validates :event_category, presence: true

    enum event_category: {
      favorite_game: 2
    }
  end
end
