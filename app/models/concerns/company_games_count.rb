# frozen_string_literal: true

# Keeps `companies.games_count` up to date from GameDeveloper and
# GamePublisher. A plain counter cache can't, because a game the company both
# developed and published counts once, so each change recounts the company
# instead (two index scans).
#
# Writes that skip callbacks (update_all, raw SQL) leave the count stale until
# the daily ResourceGameCountsSync fixes it.
module CompanyGamesCount
  extend ActiveSupport::Concern

  # Counts one company's distinct games, as a correlated subquery on companies.
  COUNT_SQL = <<~SQL.squish.freeze
    (SELECT COUNT(*) FROM (
      SELECT game_id FROM game_developers WHERE game_developers.company_id = companies.id
      UNION
      SELECT game_id FROM game_publishers WHERE game_publishers.company_id = companies.id
    ) company_games)
  SQL

  included do
    after_create :recount_company_games
    after_destroy :recount_company_games
    after_update :recount_company_games, if: -> { saved_change_to_company_id? || saved_change_to_game_id? }
  end

  # @param company_ids [Array<Integer>]
  def self.recount(company_ids)
    companies = Company.where(id: company_ids.compact.uniq)
    # Lock first, in a fixed order. Otherwise two transactions adding games to
    # the same company at once each recount without seeing the other's row,
    # and the second to commit overwrites the first's count. Once the lock is
    # free, the UPDATE takes a fresh snapshot that sees the other's rows.
    companies.order(:id).lock.pluck(:id)
    companies.update_all("games_count = #{COUNT_SQL}") # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def recount_company_games
    CompanyGamesCount.recount([company_id, company_id_before_last_save])
  end
end
