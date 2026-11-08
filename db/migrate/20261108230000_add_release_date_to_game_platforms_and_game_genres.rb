# frozen_string_literal: true

# Copies each game's release date onto its game_platforms and game_genres rows,
# so that a platform's or genre's games can be listed newest-first straight
# from an index on the join table (added in the next migration) instead of
# fetching and sorting every game on the platform.
#
# Triggers keep the copies in sync rather than model callbacks, so that no
# write path (update_all, raw SQL, a game merge) can leave them stale:
#
# - Inserting or updating a join row copies the release date from its game.
# - Changing a game's release date copies it to all of its join rows.
class AddReleaseDateToGamePlatformsAndGameGenres < ActiveRecord::Migration[7.2]
  JOIN_TABLES = [:game_platforms, :game_genres].freeze

  def up
    execute <<~SQL # rubocop:disable Rails/SquishedSQLHeredocs -- keeps the function readable in structure.sql
      CREATE FUNCTION copy_release_date_from_game() RETURNS trigger
      LANGUAGE plpgsql AS $$
      BEGIN
        SELECT release_date INTO NEW.release_date FROM public.games WHERE id = NEW.game_id;
        RETURN NEW;
      END;
      $$
    SQL

    JOIN_TABLES.each do |table|
      add_column table, :release_date, :date

      execute <<~SQL.squish
        CREATE TRIGGER copy_release_date_from_game
        BEFORE INSERT OR UPDATE ON #{table}
        FOR EACH ROW EXECUTE FUNCTION copy_release_date_from_game()
      SQL

      execute <<~SQL.squish
        UPDATE #{table} SET release_date = games.release_date
        FROM games
        WHERE games.id = #{table}.game_id AND games.release_date IS NOT NULL
      SQL
    end

    execute <<~SQL # rubocop:disable Rails/SquishedSQLHeredocs
      CREATE FUNCTION copy_release_date_to_game_joins() RETURNS trigger
      LANGUAGE plpgsql AS $$
      BEGIN
        UPDATE public.game_platforms SET release_date = NEW.release_date WHERE game_id = NEW.id;
        UPDATE public.game_genres SET release_date = NEW.release_date WHERE game_id = NEW.id;
        RETURN NULL;
      END;
      $$
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER copy_release_date_to_game_joins
      AFTER UPDATE OF release_date ON games
      FOR EACH ROW
      WHEN (OLD.release_date IS DISTINCT FROM NEW.release_date)
      EXECUTE FUNCTION copy_release_date_to_game_joins()
    SQL
  end

  def down
    execute 'DROP TRIGGER copy_release_date_to_game_joins ON games'
    execute 'DROP FUNCTION copy_release_date_to_game_joins()'

    JOIN_TABLES.each do |table|
      execute "DROP TRIGGER copy_release_date_from_game ON #{table}"
      remove_column table, :release_date
    end

    execute 'DROP FUNCTION copy_release_date_from_game()'
  end
end
