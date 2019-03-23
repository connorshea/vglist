FactoryBot.define do
  factory :genre do
    name { "First-person shooter" }

    trait :description do
      description { "A video game genre centered around gun and other weapon-based combat in a first-person perspective." }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :genre_with_everything, traits: [:description, :wikidata_id]
  end
end
