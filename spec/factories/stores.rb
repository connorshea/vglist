# typed: false
FactoryBot.define do
  factory :store do
    name { Faker::Game.store }
  end
end
