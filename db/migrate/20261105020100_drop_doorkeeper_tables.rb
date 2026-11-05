# frozen_string_literal: true

# Third-party OAuth (Doorkeeper) was removed along with the public API. The
# table definitions are kept here so the migration can be rolled back, but
# rolling back does not restore any applications or tokens.
class DropDoorkeeperTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :oauth_access_grants do |t|
      t.references :resource_owner, null: false, index: true, foreign_key: { to_table: :users }
      t.references :application, null: false, index: true, foreign_key: { to_table: :oauth_applications }
      t.string :token, null: false, index: { unique: true }
      t.integer :expires_in, null: false
      t.text :redirect_uri, null: false
      t.datetime :created_at, null: false, precision: nil
      t.string :scopes, null: false, default: ''
      t.datetime :revoked_at, precision: nil
    end

    drop_table :oauth_access_tokens do |t|
      t.references :resource_owner, index: true, foreign_key: { to_table: :users }
      t.references :application, null: false, index: true, foreign_key: { to_table: :oauth_applications }
      t.string :token, null: false, index: { unique: true }
      t.string :refresh_token, index: { unique: true }
      t.integer :expires_in
      t.datetime :revoked_at, precision: nil
      t.datetime :created_at, null: false, precision: nil
      t.string :scopes
      t.string :previous_refresh_token, null: false, default: ''
    end

    drop_table :oauth_applications do |t|
      t.string :name, null: false
      t.string :uid, null: false, index: { unique: true }
      t.string :secret, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps
      t.integer :owner_id
      t.string :owner_type
      t.index [:owner_id, :owner_type]
    end
  end
end
