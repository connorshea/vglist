# typed: strict

module Views
  # A view for aggregating data from the various events tables.
  class NewEvent < ApplicationRecord
    self.table_name = 'new_events'

    # Readonly since this is a view and we can't edit it.
    readonly

    enum event_category: {
      add_to_library: 0,
      change_completion_status: 1,
      favorite_game: 2,
      new_user: 3,
      following: 4
    }
  end
end
