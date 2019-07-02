# typed: true
if defined?(Faker)
  module GameProperties
    class Game < Faker::Base
      class << self
        extend T::Sig
        
        sig { returns(String) }
        def name
          fetch('game.name')
        end

        sig { returns(String) }
        def platform
          fetch('game.platform')
        end

        sig { returns(String) }
        def genre
          fetch('game.genre')
        end

        sig { returns(String) }
        def company
          fetch('game.company')
        end

        sig { returns(String) }
        def engine
          fetch('game.engine')
        end

        sig { returns(String) }
        def series
          fetch('game.series')
        end
      end
    end
  end

  Faker.prepend GameProperties
end
