# frozen_string_literal: true

module Resolvers::AdminResolvers
  class GroupedUnmatchedGamesResolver < Resolvers::BaseResolver
    type Types::GroupedUnmatchedGameType.connection_type, null: true

    description "List all unmatched game entries."

    def resolve
      # The view sorts by count alone, so break ties to keep cursor pages stable.
      Views::GroupedUnmatchedGame.order(count: :desc, external_service_name: :asc, external_service_id: :asc)
    end

    # Allow anyone to access this, there's not really any reason to limit who can see these.
    def authorized?
      true
    end
  end
end
