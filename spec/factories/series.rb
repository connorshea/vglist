FactoryBot.define do
  factory :series do
    name { "Half-Life" }
    wikidata_id { Faker::Number.number(digits: 6) }

    trait :game do
      after(:create) { |series| create(:game, series: series) }
    end

    factory :series_with_everything, traits: [:game]
  end
end
