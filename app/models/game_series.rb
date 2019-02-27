class GameSeries < ApplicationRecord
  belongs_to :game
  belongs_to :series

  validates :game_id, uniqueness: true
end
