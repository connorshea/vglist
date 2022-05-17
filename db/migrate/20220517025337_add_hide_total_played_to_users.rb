# typed: true
class AddHideTotalPlayedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :hide_days_played, :boolean, default: false
  end
end
