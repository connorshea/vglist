# typed: true
class ReplaceBeforeAfterValuesWithDifferencesColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :game_purchase_events, :before_value, :text
    remove_column :game_purchase_events, :after_value, :text
    add_column :game_purchase_events, :differences, :jsonb
  end
end
