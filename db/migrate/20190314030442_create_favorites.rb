class CreateFavorites < ActiveRecord::Migration[5.2]
  def change
    create_table :favorites do |t|
      t.references :favoritable, polymorphic: true, index: true
      t.references :user, index: true

      t.timestamps
    end

    add_index :favorites, :favoritable_id
    add_index :favorites, :favoritable_type
    add_index :favorites, [:favoritable_id, :favoritable_type], unique: true
  end
end
