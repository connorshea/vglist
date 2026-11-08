# frozen_string_literal: true

class GamePlatform < ApplicationRecord
  belongs_to :game
  belongs_to :platform, counter_cache: :games_count

  validates :game_id,
    uniqueness: { scope: :platform_id }
end
