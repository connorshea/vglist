# frozen_string_literal: true

# Giant Bomb moved its wiki to MediaWiki, so the old "3030-1539"-style IDs
# (Wikidata P5247, now labelled "Giant Bomb ID (former scheme)") no longer
# resolve. The new IDs are wiki page titles like "Games/Portal_2" (Wikidata
# P14470, "Giant Bomb Wiki ID"), and they can't be derived from the old ones.
#
# Clear the old IDs so they stop producing dead links and stop failing the new
# format validation on every game edit. Run `rake import:giantbomb` afterwards
# to fill in the new IDs from Wikidata.
#
# Irreversible on purpose: the old IDs are still on Wikidata under P5247 if
# they're ever needed.
class ClearFormerSchemeGiantbombIds < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE games SET giantbomb_id = NULL WHERE giantbomb_id ~ '^[0-9]{4}-[0-9]+$'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
