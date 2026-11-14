# frozen_string_literal: true

# Stores each company's game count (developed or published, each game once)
# on the company, like the games_count counter caches on genres, platforms,
# engines and series. The companies index sorted by a correlated UNION count
# over every company instead, which took about 2 seconds in production.
#
# GameDeveloper and GamePublisher callbacks keep it up to date (see
# CompanyGamesCount), and the daily ResourceGameCountsSync fixes any drift.
class AddGamesCountToCompanies < ActiveRecord::Migration[8.1]
  def up
    add_column :companies, :games_count, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE companies SET games_count = counts.games_count
      FROM (
        SELECT company_id, COUNT(*) AS games_count FROM (
          SELECT company_id, game_id FROM game_developers
          UNION
          SELECT company_id, game_id FROM game_publishers
        ) company_games
        GROUP BY company_id
      ) counts
      WHERE counts.company_id = companies.id
    SQL

    # For the most_games order, which ends on the ID.
    add_index :companies, [:games_count, :id], order: { games_count: :desc }
  end

  def down
    remove_index :companies, [:games_count, :id]
    remove_column :companies, :games_count
  end
end
