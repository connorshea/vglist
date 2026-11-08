# frozen_string_literal: true

class GameEngine < ApplicationRecord
  belongs_to :game
  belongs_to :engine, counter_cache: :games_count

  validates :game_id,
    uniqueness: { scope: :engine_id }
end
