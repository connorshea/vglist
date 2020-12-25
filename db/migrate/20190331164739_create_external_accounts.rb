class CreateExternalAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :external_accounts do |t|
      t.references :user, index: true, null: false
      t.integer :account_type, null: false
      # Steam IDs are quite large, use a bigint.
      t.integer :steam_id, index: { unique: true }, limit: 5
      t.text :steam_profile_url

      t.timestamps
    end

    # Users can only have one account per account type.
    add_index :external_accounts, [:user_id, :account_type], unique: true
  end
end
