FactoryBot.define do
  factory :engine do
    name { "Source Engine" }

    trait :game do
      after(:create) { |engine| create(:game_engine, engine: engine) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :engine_with_everything, traits: [:game, :wikidata_id]
  end
end
