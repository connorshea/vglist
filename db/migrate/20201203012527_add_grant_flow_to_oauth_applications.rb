# typed: true
class AddGrantFlowToOauthApplications < ActiveRecord::Migration[6.0]
  def change
    change_table :oauth_applications do |t|
      t.integer :grant_flow, default: 0, null: false
    end
  end
end
