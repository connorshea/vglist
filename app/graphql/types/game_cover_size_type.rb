# typed: strict
module Types
  class GameCoverSizeType < Types::BaseEnum
    description <<~DESCRIPTION
      The size of the game cover. Game covers are downsized to fit
      within the specified dimensions while retaining the original aspect
      ratio. Will only resize the image if it\'s larger than the specified
      dimensions.
    DESCRIPTION

    Game::COVER_SIZES.each do |key, (width, height)|
      value key.to_s.upcase, value: key, description: "Game cover image with a maximum width of #{width} and maximum height of #{height}."
    end
  end
end
