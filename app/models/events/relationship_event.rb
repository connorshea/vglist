# typed: strict
module Events
  class RelationshipEvent < ApplicationRecord
    belongs_to :eventable, class_name: 'Relationship'
    belongs_to :user, inverse_of: :relationship_events

    validates :event_category, presence: true

    enum event_category: {
      following: 4
    }
  end
end
