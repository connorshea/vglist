# frozen_string_literal: true

# Stores each company's game count (developed or published, each game once)
# on the company, like the games_count counter caches on genres, platforms,
# engines and series. The companies index sorted by a correlated UNION count
# over every company instead, which took about 2 seconds in production.
#
# A counter cache can't count this: a game the company both developed and
# published counts once, so whether adding or removing a row changes the
# count depends on the other table. Triggers recount the company instead,
# which takes a couple of index scans, and keep the count right for every
# write path (update_all, raw SQL, a game or company merge).
class AddGamesCountToCompanies < ActiveRecord::Migration[8.1]
  JOIN_TABLES = [:game_developers, :game_publishers].freeze

  def up
    add_column :companies, :games_count, :integer, default: 0, null: false

    execute <<~SQL
      CREATE FUNCTION refresh_company_games_count() RETURNS trigger
      LANGUAGE plpgsql AS $$
      DECLARE
        changed_company_ids bigint[];
      BEGIN
        IF TG_OP = 'INSERT' THEN
          changed_company_ids := ARRAY[NEW.company_id];
        ELSIF TG_OP = 'DELETE' THEN
          changed_company_ids := ARRAY[OLD.company_id];
        ELSE
          changed_company_ids := ARRAY[OLD.company_id, NEW.company_id];
        END IF;

        -- Lock the companies first. Otherwise two transactions that add games to
        -- the same company at once each recount without seeing the other's row,
        -- and the second one to commit overwrites the first one's count. Once
        -- the lock is free, the UPDATE below takes a fresh snapshot that sees
        -- the other transaction's rows.
        PERFORM 1 FROM public.companies WHERE id = ANY(changed_company_ids) ORDER BY id FOR UPDATE;

        UPDATE public.companies
        SET games_count = (
          SELECT COUNT(*) FROM (
            SELECT game_id FROM public.game_developers WHERE company_id = companies.id
            UNION
            SELECT game_id FROM public.game_publishers WHERE company_id = companies.id
          ) company_games
        )
        WHERE id = ANY(changed_company_ids);

        RETURN NULL;
      END;
      $$
    SQL

    JOIN_TABLES.each do |table|
      execute <<~SQL.squish
        CREATE TRIGGER refresh_company_games_count
        AFTER INSERT OR DELETE OR UPDATE OF company_id, game_id ON #{table}
        FOR EACH ROW EXECUTE FUNCTION refresh_company_games_count()
      SQL
    end

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

    JOIN_TABLES.each do |table|
      execute "DROP TRIGGER refresh_company_games_count ON #{table}"
    end
    execute 'DROP FUNCTION refresh_company_games_count()'

    remove_column :companies, :games_count
  end
end
