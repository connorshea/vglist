module Views
  # A view for aggregating data from the various events tables.
  class NewEvent < ApplicationRecord
    self.table_name = 'new_events'
    self.primary_key = 'id'

    # Readonly since this is a view and we can't edit it.
    readonly

    # belongs_to :eventable
    belongs_to :user, inverse_of: :new_events

    scope :recently_created, -> { order("created_at desc") }

    enum :event_category, {
      add_to_library: 0,
      change_completion_status: 1,
      favorite_game: 2,
      new_user: 3,
      following: 4
    }

    # Get a specific event subclass record based on the ID.
    def self.find_event_subclass_by_id(id)
      event =   Events::GamePurchaseEvent.find_by(id: id)
      event ||= Events::FavoriteGameEvent.find_by(id: id)
      event ||= Events::UserEvent.find_by(id: id)
      event ||= Events::RelationshipEvent.find_by(id: id)
      event
    end

    def subclass
      Views::NewEvent.find_event_subclass_by_id(id)
    end

    def eventable
      subclass&.eventable
    end
  end
end
