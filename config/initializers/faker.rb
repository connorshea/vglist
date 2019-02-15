if defined?(Faker)
  module GameProperties
    class Game < Faker::Base
      class << self
        def name
          fetch('game.name')
        end

        def platform
          fetch('game.platform')
        end

        def genre
          fetch('game.genre')
        end

        def company
          fetch('game.company')
        end

        def engine
          fetch('game.engine')
        end
      end
    end
  end

  Faker.prepend GameProperties
end
