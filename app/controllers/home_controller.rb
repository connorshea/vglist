class HomeController < ApplicationController
  layout "application_no_padding"

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

    @games = Game.recently_updated
                 .with_attached_cover
                 .includes(:platforms, :developers)
                 .limit(18)
  end
end
