# typed: false
FactoryBot.define do
  factory :company do
    name { "Valve Corporation" }

    trait :game_as_developer do
      after(:create) { |company| create(:game_developer, company: company) }
    end

    trait :game_as_publisher do
      after(:create) { |company| create(:game_publisher, company: company) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    factory :company_with_everything, traits: [:game_as_developer, :game_as_publisher, :wikidata_id]
  end
end
