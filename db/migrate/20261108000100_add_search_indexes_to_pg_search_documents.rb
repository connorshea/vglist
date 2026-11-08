# frozen_string_literal: true

# Indexes pg_search_documents for PgSearch.multisearch (global search), which
# combines tsearch and trigram matching (config/initializers/pg_search.rb).
# Without these, every search did a sequential scan of the whole table, once
# per searchable type.
#
# The expressions must match the SQL pg_search generates, or Postgres won't
# use the indexes:
#
#   to_tsvector('simple', coalesce(content::text, '')) @@ to_tsquery(...)
#   'query' % coalesce(content::text, '')
#
# App Platform runs migrations in a pre-deploy job, so the indexes are built
# concurrently to keep the table writable. A cancelled concurrent build leaves
# an INVALID index behind, which IF NOT EXISTS would happily skip, so any
# invalid leftover is dropped and rebuilt first.
#
# Raw SQL because add_index doesn't apply an opclass to an expression.
class AddSearchIndexesToPgSearchDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  INDEXES = {
    'index_pg_search_documents_on_content_tsvector' =>
      "(to_tsvector('simple', coalesce(content::text, '')))",
    'index_pg_search_documents_on_content_trigram' =>
      "(coalesce(content::text, '') gin_trgm_ops)"
  }.freeze

  def up
    INDEXES.each do |name, expression|
      drop_invalid_index(name)
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS #{name}
        ON pg_search_documents USING gin #{expression}
      SQL
    end
  end

  def down
    INDEXES.each_key do |name|
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{name}"
    end
  end

  private

  def drop_invalid_index(name)
    invalid = select_value(<<~SQL.squish)
      SELECT 1 FROM pg_index
      JOIN pg_class ON pg_class.oid = pg_index.indexrelid
      WHERE pg_class.relname = #{connection.quote(name)} AND NOT pg_index.indisvalid
    SQL
    execute "DROP INDEX CONCURRENTLY #{name}" if invalid
  end
end
