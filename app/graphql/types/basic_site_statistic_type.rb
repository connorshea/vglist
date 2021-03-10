# typed: strict
module Types
  class BasicSiteStatisticType < Types::BaseObject
    description "Basic site statistics."

    field :games, Integer, null: false, description: "The current number of Games."
    field :platforms, Integer, null: false, description: "The current number of Platforms."
    field :series, Integer, null: false, description: "The current number of Series'."
    field :engines, Integer, null: false, description: "The current number of Engines."
    field :companies, Integer, null: false, description: "The current number of Companies."
    field :genres, Integer, null: false, description: "The current number of Genres."
  end
end
