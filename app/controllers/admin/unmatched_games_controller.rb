# typed: true
class Admin::UnmatchedGamesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize nil, policy_class: Admin::UnmatchedGamesPolicy
    skip_policy_scope

    @unmatched_games = UnmatchedGame.all
                                    .includes(:user)
                                    .page helpers.page_param
  end
end

