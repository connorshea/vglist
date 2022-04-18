# typed: true
class CreateGroupedUnmatchedGamesView < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      CREATE OR REPLACE VIEW public.grouped_unmatched_games AS
        SELECT
          COUNT(*),
          external_service_id,
          external_service_name,
          array_agg(name) as names
        FROM
          unmatched_games
        GROUP BY
          external_service_id,
          external_service_name
        ORDER BY COUNT DESC;
    SQL
  end

  def down
    execute('DROP VIEW IF EXISTS public.grouped_unmatched_games;')
  end
end
