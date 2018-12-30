module GameName
  class Game < Faker::Base
    class << self
      def name
        fetch('game.name')
      end
    end
  end
end

Faker.prepend GameName
