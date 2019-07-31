# typed: false
FactoryBot.define do
  factory :platform do
    name { "Xbox 360" }

    trait :description do
      description { "A video game console by Microsoft." }
    end

    trait :game do
      after(:create) { |platform| create(:game_platform, platform: platform) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    factory :platform_with_everything, traits: [:description, :game, :wikidata_id]
  end
end
