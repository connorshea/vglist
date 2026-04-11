# frozen_string_literal: true

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
  end
end
