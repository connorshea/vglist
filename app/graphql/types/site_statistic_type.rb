# typed: strict
module Types
  class SiteStatisticType < Types::BaseObject
    description <<~MARKDOWN
      Historical site statistics for vglist. Most of these values cannot be
      `null`, but some may be if you go back far enough. Make sure to handle
      `null` where necessary.
    MARKDOWN

    implements Types::SiteStatisticItem

    field :id, ID, null: false, description: "ID of the statistic record."

    # Actually #created_at, but timestamp works better.
    field :timestamp, GraphQL::Types::ISO8601DateTime,
      null: false,
      method: :created_at,
      description: "The point in time at which these statistics were logged, always UTC."
  end
end
