FactoryBot.define do
  factory :engine do
    name { "Source Engine" }
    wikidata_id { Faker::Number.number(digits: 6) }

    trait :game do
      after(:create) { |engine| create(:game_engine, engine: engine) }
    end

    factory :engine_with_everything, traits: [:game]
  end
end
