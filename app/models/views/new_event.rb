# typed: strict

module Views
  # A view for aggregating data from the various events tables.
  class NewEvent < ApplicationRecord
    self.table_name = 'new_events'
    self.primary_key = 'id'

    # Create a type alias for representing a method that can take/return any of the
    # event subclasses.
    NewEventSubclasses = T.type_alias { T.any(Events::FavoriteGameEvent, Events::RelationshipEvent, Events::UserEvent, Events::GamePurchaseEvent) }
    Eventables = T.type_alias { T.any(User, GamePurchase, Relationship, FavoriteGame) }

    # Readonly since this is a view and we can't edit it.
    readonly

    # belongs_to :eventable
    belongs_to :user, inverse_of: :new_events

    scope :recently_created, -> { order("created_at desc") }

    enum event_category: {
      add_to_library: 0,
      change_completion_status: 1,
      favorite_game: 2,
      new_user: 3,
      following: 4
    }

    # Get a specific event subclass record based on the ID.
    sig { params(id: String).returns(T.nilable(NewEventSubclasses)) }
    def self.find_event_subclass_by_id(id)
      event =   Events::GamePurchaseEvent.find_by(id: id)
      event ||= Events::FavoriteGameEvent.find_by(id: id)
      event ||= Events::UserEvent.find_by(id: id)
      event ||= Events::RelationshipEvent.find_by(id: id)
      event
    end

    sig { returns(T.nilable(NewEventSubclasses)) }
    def subclass
      Views::NewEvent.find_event_subclass_by_id(id)
    end

    sig { returns(T.nilable(Eventables)) }
    def eventable
      subclass&.eventable
    end
  end
end
