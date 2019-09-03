class CreateRelationships < ActiveRecord::Migration[6.0]
  def change
    create_table :relationships do |t|
      t.references :follower,
        null: false,
        index: true,
        foreign_key: { to_table: :users }

      t.references :followed,
        null: false,
        index: true,
        foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
