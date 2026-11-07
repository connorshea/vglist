# frozen_string_literal: true

# Single-use WebAuthn challenges. The API has no cookie session to keep them
# in, and Rails.cache is per Puma worker in production, so they live here
# between the "options" request and the "verify" request.
class CreateWebauthnChallenges < ActiveRecord::Migration[7.2]
  def change
    create_table :webauthn_challenges do |t|
      t.string :challenge, null: false, index: { unique: true }
      t.integer :purpose, null: false
      t.references :user, null: true, index: true, foreign_key: { on_delete: :cascade }
      t.datetime :expires_at, null: false, index: true
      t.datetime :created_at, null: false
    end
  end
end
