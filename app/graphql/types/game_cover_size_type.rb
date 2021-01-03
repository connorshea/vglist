# typed: strict
module Types
  class GameCoverSizeType < Types::BaseEnum
    description "The size of the game cover."

    Game::COVER_SIZES.each do |key, (width, height)|
      value key.to_s.upcase, value: key, description: "Game cover image with a width of #{width} and height of #{height}."
    end
  end
end
