# typed: false
FactoryBot.define do
  factory :company do
    name { "Valve Corporation" }
    wikidata_id { Faker::Number.number(digits: 6) }

    trait :game_as_developer do
      after(:create) { |company| create(:game_developer, company: company) }
    end

    trait :game_as_publisher do
      after(:create) { |company| create(:game_publisher, company: company) }
    end

    factory :company_with_everything, traits: [:game_as_developer, :game_as_publisher]
  end
end
