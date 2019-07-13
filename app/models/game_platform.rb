# typed: strong
class GamePlatform < ApplicationRecord
  belongs_to :game
  belongs_to :platform

  validates :game_id,
    uniqueness: { scope: :platform_id }
end
