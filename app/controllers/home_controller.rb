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

    @games = Rails.cache.fetch("home_page_games_#{ENV['GIT_COMMIT_SHA']}", expires_in: 15.minutes) do
      Game.recently_updated
          .joins(:cover_attachment)
          .with_attached_cover
          .includes(:platforms, :developers)
          .limit(18)
    end
  end
end
