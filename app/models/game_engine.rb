# typed: strong
class GameEngine < ApplicationRecord
  belongs_to :game
  belongs_to :engine

  validates :game_id,
    uniqueness: { scope: :engine_id }
end
