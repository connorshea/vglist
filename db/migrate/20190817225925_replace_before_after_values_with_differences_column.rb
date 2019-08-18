# typed: true
# rubocop:disable Rails/BulkChangeTable
# There's a bug in rubocop where remove_column is recommended to be replaced by
# this cop, even though its replacement wouldn't be reversible.
class ReplaceBeforeAfterValuesWithDifferencesColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :game_purchase_events, :before_value, :text
    remove_column :game_purchase_events, :after_value, :text
    add_column :game_purchase_events, :differences, :jsonb
  end
end
