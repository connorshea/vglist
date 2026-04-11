# frozen_string_literal: true

FactoryBot.define do
  factory :favorite_game do
    user
    game
  end
end
