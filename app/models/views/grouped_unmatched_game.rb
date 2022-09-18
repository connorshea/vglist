# typed: true

module Views
  # A view for performantly grouping unmatched games together based on
  # their external service IDs. This allows us to expose the expected data
  # for the rendered table in the frontend and also sort by the count.
  class GroupedUnmatchedGame < ApplicationRecord
    self.table_name = 'grouped_unmatched_games'

    # Readonly since this is a view and we can't edit it.
    readonly

    # The names will almost always be the same for every entry, but we don't
    # group them by name just in case. Rather than trying to find the most
    # common name, we can just pick the first one in the list for
    # simplicity/performance.
    def name
      names.first
    end
  end
end
