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
    end
  end
end

Faker.prepend GameProperties
