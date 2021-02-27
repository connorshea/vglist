# typed: false
class AddConstraintsToEvents < ActiveRecord::Migration[6.1]
  # Event categories and corresponding eventable types:
  # add_to_library: 0 => GamePurchase
  # change_completion_status: 1 => GamePurchase
  # favorite_game: 2 => FavoriteGame
  # new_user: 3 => User
  # following: 4 => Relationship
  CONSTRAINT = <<~SQL.squish
    (event_category IN (0, 1) AND eventable_type = 'GamePurchase')
    OR (event_category = 2 AND eventable_type = 'FavoriteGame')
    OR (event_category = 3 AND eventable_type = 'User')
    OR (event_category = 4 AND eventable_type = 'Relationship')
  SQL

  def change
    add_check_constraint :events, CONSTRAINT, name: "event_category_type_check"
  end
end
