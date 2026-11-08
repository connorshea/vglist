# frozen_string_literal: true

class GameGenre < ApplicationRecord
  belongs_to :game
  belongs_to :genre, counter_cache: :games_count

  validates :game_id,
    uniqueness: { scope: :genre_id }
end
