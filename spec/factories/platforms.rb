FactoryBot.define do
  factory :platform do
    name { "Xbox 360" }
    description { "A video game console by Microsoft." }

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :platform_with_everything, traits: [:wikidata_id]
  end
end
