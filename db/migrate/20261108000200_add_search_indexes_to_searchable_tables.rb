# frozen_string_literal: true

# Indexes the `searchable` scopes (Game.search, Company.search, ...) that back
# the games index filter and the search-as-you-type pickers. pg_search builds
# their WHERE clause as
#
#   to_tsvector('simple', coalesce(<column>::text, '')) @@ to_tsquery(...)
#
# so each index uses that exact expression. Platforms, genres and stores are
# skipped: they hold a few hundred rows, and Postgres would scan them anyway.
#
# Built concurrently (App Platform runs migrations in a pre-deploy job). A
# cancelled concurrent build leaves an INVALID index, which IF NOT EXISTS
# would skip, so any invalid leftover is dropped and rebuilt first.
class AddSearchIndexesToSearchableTables < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  COLUMNS = {
    games: :name,
    companies: :name,
    series: :name,
    engines: :name,
    users: :username
  }.freeze

  def up
    COLUMNS.each do |table, column|
      name = index_name_for(table, column)
      drop_invalid_index(name)
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS #{name}
        ON #{table} USING gin (to_tsvector('simple', coalesce(#{column}::text, '')))
      SQL
    end
  end

  def down
    COLUMNS.each do |table, column|
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{index_name_for(table, column)}"
    end
  end

  private

  def index_name_for(table, column)
    "index_#{table}_on_#{column}_tsvector"
  end

  def drop_invalid_index(name)
    invalid = select_value(<<~SQL.squish)
      SELECT 1 FROM pg_index
      JOIN pg_class ON pg_class.oid = pg_index.indexrelid
      WHERE pg_class.relname = #{connection.quote(name)} AND NOT pg_index.indisvalid
    SQL
    execute "DROP INDEX CONCURRENTLY #{name}" if invalid
  end
end
