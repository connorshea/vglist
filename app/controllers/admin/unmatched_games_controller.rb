# typed: true
class Admin::UnmatchedGamesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize nil, policy_class: Admin::UnmatchedGamesPolicy
    skip_policy_scope

    @unmatched_games = Views::GroupedUnmatchedGame.where(external_service_name: 'Steam')
                                                  .page helpers.page_param
  end

  def destroy
    authorize nil, policy_class: Admin::UnmatchedGamesPolicy
    skip_policy_scope

    unmatched_games = UnmatchedGame.where(
      external_service_id: params[:external_service_id],
      external_service_name: params[:external_service_name]
    )

    unmatched_games.each(&:destroy!)

    redirect_to admin_unmatched_games_url, success: "Unmatched game records were successfully deleted."
  end
end

