# typed: false
FactoryBot.define do
  factory :genre do
    name { "First-person shooter" }
    wikidata_id { Faker::Number.number(digits: 6) }

    trait :game do
      after(:create) { |genre| create(:game_genre, genre: genre) }
    end

    factory :genre_with_everything, traits: [:game]
  end
end
