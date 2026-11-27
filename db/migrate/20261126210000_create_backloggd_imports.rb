# frozen_string_literal: true

class CreateBackloggdImports < ActiveRecord::Migration[8.1]
  def change
    create_table :backloggd_imports, comment: "A user's most recent import from Backloggd, which runs in a background job." do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.text :username, null: false, comment: 'The Backloggd username the games were imported from.'
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.bigint :added_game_ids, array: true, null: false, default: []
      t.bigint :updated_game_ids, array: true, null: false, default: []
      t.jsonb :unmatched_games, null: false, default: [], comment: 'The games that could not be matched, as [{ name, slug }].'
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
  end
end
