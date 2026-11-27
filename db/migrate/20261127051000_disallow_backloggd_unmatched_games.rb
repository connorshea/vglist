# frozen_string_literal: true

# Undoes AllowBackloggdUnmatchedGames now that the Backloggd import is gone.
# Any unmatched games it logged are deleted, since nothing can show or act on
# them anymore and the check constraint would reject them.
class DisallowBackloggdUnmatchedGames < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM unmatched_games WHERE external_service_name = 'Backloggd'"
    remove_check_constraint :unmatched_games, name: 'validate_external_service_name'
    add_check_constraint :unmatched_games, "external_service_name IN ('Steam')", name: 'validate_external_service_name'
  end

  def down
    remove_check_constraint :unmatched_games, name: 'validate_external_service_name'
    add_check_constraint :unmatched_games, "external_service_name IN ('Steam', 'Backloggd')", name: 'validate_external_service_name'
  end
end
