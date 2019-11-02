# typed: false
FactoryBot.define do
  factory :genre do
    name { "First-person shooter" }

    trait :game do
      after(:create) { |genre| create(:game_genre, genre: genre) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    factory :genre_with_everything, traits: [:game, :wikidata_id]
  end
end
