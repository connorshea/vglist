FactoryBot.define do
  factory :engine do
    name { "Source Engine" }

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :engine_with_everything, traits: [:wikidata_id]
  end
end
