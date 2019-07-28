# typed: true
class RemoveReleases < ActiveRecord::Migration[5.2]
  def up
    drop_table :release_purchases
    drop_table :release_developers
    drop_table :release_publishers
    drop_table :releases
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
