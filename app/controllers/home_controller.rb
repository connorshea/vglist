class HomeController < ApplicationController
  def index
    skip_policy_scope

    # TODO: Cache these.
    @counts = {
      games: Game.count,
      platforms: Platform.count,
      series: Series.count,
      engines: Engine.count,
      companies: Company.count
    }
  end
end
