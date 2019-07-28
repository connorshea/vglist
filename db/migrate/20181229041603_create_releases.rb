# typed: true
class CreateReleases < ActiveRecord::Migration[5.2]
  def change
    create_table :releases do |t|
      t.text :name
      t.text :description
      t.references :platform, null: false
      t.references :game, null: false

      t.timestamps
    end

    add_foreign_key :releases, :games,
      on_delete: :cascade
    add_foreign_key :releases, :platforms,
      on_delete: :cascade
  end
end
