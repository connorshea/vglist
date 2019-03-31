class RemovePlpgsqlExtension < ActiveRecord::Migration[5.2]
  # The separate methods make the migration reversible.
  # This extension shouldn't be used.
  def up
    execute "drop extension plpgsql;"
  end

  def down
    execute "create extension plpgsql;"
  end
end
