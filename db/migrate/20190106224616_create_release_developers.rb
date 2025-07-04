class CreateReleaseDevelopers < ActiveRecord::Migration[5.2]
  def change
    create_table :release_developers do |t|
      t.references :release, null: false
      t.references :company, null: false

      t.timestamps
    end

    add_foreign_key :release_developers, :releases,
      on_delete: :cascade
    add_foreign_key :release_developers, :companies,
      on_delete: :cascade
  end
end
