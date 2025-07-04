if defined?(Faker)
  # Add custom methods to the Game Faker.
  module Faker
    class Game < Faker::Base
      def self.company
        fetch('game.company')
      end

      def self.engine
        fetch('game.engine')
      end

      def self.series
        fetch('game.series')
      end

      def self.store
        fetch('game.store')
      end
    end

    # Add a custom image faker.
    class Image < Faker::Base
      def self.unsplash(category: nil, width: 400, height: 400, keyword: nil)
        url = 'https://source.unsplash.com'
        url += "/category/#{category}" unless category.nil?
        url += "/#{width}x#{height}"
        url += "?#{keyword}" unless keyword.nil?
        url
      end
    end
  end
end
