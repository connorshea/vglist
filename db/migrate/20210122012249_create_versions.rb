# typed: false
# This migration creates the various `versions` tables, the only schema
# PaperTrail requires.
# All other migrations PT provides are optional.
class CreateVersions < ActiveRecord::Migration[6.1]
  def change
    create_table :company_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    create_table :engine_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    create_table :game_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    create_table :genre_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    create_table :platform_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    create_table :series_versions do |t|
      t.text     :item_type, null: false
      t.bigint   :item_id,   null: false
      t.text     :event,     null: false
      t.text     :whodunnit
      t.bigint   :whodunnit_id
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
    end

    add_index :company_versions,  [:item_type, :item_id]
    add_index :engine_versions,   [:item_type, :item_id]
    add_index :game_versions,     [:item_type, :item_id]
    add_index :genre_versions,    [:item_type, :item_id]
    add_index :platform_versions, [:item_type, :item_id]
    add_index :series_versions,   [:item_type, :item_id]
  end
end
