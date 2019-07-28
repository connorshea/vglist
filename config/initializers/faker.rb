# typed: true
if defined?(Faker)
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
      end
    end
  end

  Faker.prepend GameProperties
end
