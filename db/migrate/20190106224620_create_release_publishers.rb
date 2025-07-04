class CreateReleasePublishers < ActiveRecord::Migration[5.2]
  def change
    create_table :release_publishers do |t|
      t.references :release, null: false
      t.references :company, null: false

      t.timestamps
    end

    add_foreign_key :release_publishers, :releases,
      on_delete: :cascade
    add_foreign_key :release_publishers, :companies,
      on_delete: :cascade
  end
end
