# frozen_string_literal: true

class AllowBackloggdUnmatchedGames < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :unmatched_games, name: 'validate_external_service_name'
    add_check_constraint :unmatched_games, "external_service_name IN ('Steam', 'Backloggd')", name: 'validate_external_service_name'
  end

  def down
    remove_check_constraint :unmatched_games, name: 'validate_external_service_name'
    add_check_constraint :unmatched_games, "external_service_name IN ('Steam')", name: 'validate_external_service_name'
  end
end
