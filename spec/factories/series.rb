FactoryBot.define do
  factory :series do
    name { "Half-Life" }

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :series_with_everything, traits: [:wikidata_id]
  end
end
