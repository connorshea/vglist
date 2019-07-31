# typed: false
FactoryBot.define do
  factory :genre do
    name { "First-person shooter" }

    trait :description do
      description { "A video game genre centered around gun and other weapon-based combat in a first-person perspective." }
    end

    trait :game do
      after(:create) { |genre| create(:game_genre, genre: genre) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    factory :genre_with_everything, traits: [:description, :game, :wikidata_id]
  end
end
