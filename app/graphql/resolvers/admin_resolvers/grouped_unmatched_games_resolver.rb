module Resolvers::AdminResolvers
  class GroupedUnmatchedGamesResolver < Resolvers::BaseResolver
    type Types::GroupedUnmatchedGameType.connection_type, null: true

    description "List all unmatched game entries."

    def resolve
      Views::GroupedUnmatchedGame.all
    end

    # Allow anyone to access this, there's not really any reason to limit who can see these.
    def authorized?
      true
    end
  end
end
