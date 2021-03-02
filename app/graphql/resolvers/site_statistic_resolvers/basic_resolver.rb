# typed: true
module Resolvers
  module SiteStatisticResolvers
    class BasicResolver < Resolvers::BaseResolver
      type Types::BasicSiteStatisticType, null: false

      description <<~MARKDOWN
        Current, basic site statistics for the home page. These values are
        cached for 30 minutes and so won't necessarily represent the live
        values.
      MARKDOWN

      sig { returns(T::Hash[Symbol, Integer]) }
      def resolve
        Rails.cache.fetch("home_page_counts_#{ENV['GIT_COMMIT_SHA']}", expires_in: 30.minutes) do
          {
            games: Game.count,
            platforms: Platform.count,
            series: Series.count,
            engines: Engine.count,
            companies: Company.count,
            genres: Genre.count
          }
        end
      end
    end
  end
end
