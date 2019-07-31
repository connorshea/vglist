# typed: false
FactoryBot.define do
  factory :series do
    name { "Half-Life" }

    trait :game do
      after(:create) { |series| create(:game, series: series) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    factory :series_with_everything, traits: [:game, :wikidata_id]
  end
end
