# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    # Scores a connection as if it held ~10 records (or `first`, if smaller),
    # however large a page was requested.
    #
    # By default a connection is scored as if it returned a full page (`first`,
    # or 30), which is right for top-level lists but not for associations that
    # only ever hold a handful of records, like a game's platforms or
    # developers. Those made a list of games with platforms and developers look
    # ~30 times more expensive than it is. They're preloaded in one query per
    # list, so the cost doesn't grow with the page size either.
    module ShortListComplexity
      ASSUMED_SIZE = 10

      def complexity_for(child_complexity:, query:, lookahead:) # rubocop:disable Lint/UnusedMethodArgument
        size = [lookahead.arguments[:first], lookahead.arguments[:last], ASSUMED_SIZE].compact.min
        1 + (child_complexity * size)
      end
    end

    # @param short_list [Boolean] Score this connection with ShortListComplexity.
    def initialize(*args, short_list: false, **kwargs, &block)
      super(*args, **kwargs, &block)
      extend ShortListComplexity if short_list
    end

    def resolve_field(obj, args, ctx)
      resolve(obj, args, ctx)
    end
  end
end
