# typed: strong
class FavoriteGame < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :user_id, uniqueness: {
    scope: :game_id, message: 'can only favorite a game once'
  }
end
