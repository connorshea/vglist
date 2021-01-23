# typed: true
if defined?(Faker)
  # Add custom methods to the Game Faker.
  module Faker
    class Game < Faker::Base
      extend T::Sig

      sig { returns(::String) }
      def self.company
        fetch('game.company')
      end

      sig { returns(::String) }
      def self.engine
        fetch('game.engine')
      end

      sig { returns(::String) }
      def self.series
        fetch('game.series')
      end

      sig { returns(::String) }
      def self.store
        fetch('game.store')
      end
    end

    # Add a custom image faker.
    class Image < Faker::Base
      extend T::Sig

      sig do
        params(
          category: T.nilable(::String),
          width: Integer,
          height: Integer,
          keyword: T.nilable(::String)
        ).returns(::String)
      end
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
