# typed: true
if defined?(Faker)
  # Add custom methods to the Game Faker.
  module GameProperties
    class Game < Faker::Base
      class << self
        def company
          fetch('game.company')
        end

        def engine
          fetch('game.engine')
        end

        def series
          fetch('game.series')
        end

        def store
          fetch('game.store')
        end
      end
    end
  end

  Faker.prepend GameProperties

  module Faker
    # Add a custom image faker.
    class Image < Faker::Base
      class << self
        def unsplash(category: nil, width: 400, height: 400, keyword: nil)
          url = 'https://source.unsplash.com'
          url += "/category/#{category}" unless category.nil?
          url += "/#{width}x#{height}"
          url += "?#{keyword}" unless keyword.nil?
          url
        end
      end
    end
  end
end
