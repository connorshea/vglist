class AddPgTrgmExtension < ActiveRecord::Migration[5.2]
  # The separate methods make the migration reversible.
  # This extension is necessary for trigram searches in pg_search.
  def up
    execute "create extension pg_trgm;"
  end

  def down
    execute "drop extension pg_trgm;"
  end
end
