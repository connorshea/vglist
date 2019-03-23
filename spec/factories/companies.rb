FactoryBot.define do
  factory :company do
    name { "Valve Corporation" }

    trait :description do
      description { "Valve Corporation is an American video game developer, publisher and digital distribution company headquartered in Bellevue, Washington." }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    factory :company_with_everything, traits: [:description, :wikidata_id]
  end
end
