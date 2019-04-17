class HomeController < ApplicationController
  def index
    skip_policy_scope

    @counts = Rails.cache.fetch("home_page_counts_#{ENV['GIT_COMMIT_SHA']}", expires_in: 30.minutes) do
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
