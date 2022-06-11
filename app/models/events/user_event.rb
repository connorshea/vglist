# typed: strict
module Events
  class UserEvent < ApplicationRecord
    self.table_name = 'events_user_events'

    belongs_to :eventable, class_name: 'User'
    belongs_to :user, inverse_of: :user_events

    validates :event_category, presence: true

    enum event_category: {
      new_user: 3
    }
  end
end
