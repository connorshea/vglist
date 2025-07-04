FactoryBot.define do
  factory :platform do
    name { "Xbox 360" }
    wikidata_id { Faker::Number.number(digits: 6) }

    trait :game do
      after(:create) { |platform| create(:game_platform, platform: platform) }
    end

    factory :platform_with_everything, traits: [:game]
  end
end
