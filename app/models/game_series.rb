class GameSeries < ApplicationRecord
  belongs_to :game
  belongs_to :series

  validates :game_id,
    uniqueness: { scope: :series_id }
end
