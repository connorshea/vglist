FactoryBot.define do
  factory :game do
    name { "Half-Life 2" }

    trait :description do
      description { "A 2004 first-person shooter video game created by Valve." }
    end

    trait :cover do
      after(:build) do |game|
        game.cover.attach(io: File.open(Rails.root.join('spec', 'factories', 'images', 'crysis.jpg')), filename: 'crysis.jpg', content_type: 'image/jpg')
      end
    end

    trait :series do
      series
    end

    trait :developer do
      after(:create) { |game| create(:game_developer, game: game) }
    end

    trait :publisher do
      after(:create) { |game| create(:game_publisher, game: game) }
    end

    trait :engine do
      after(:create) { |game| create(:game_engine, game: game) }
    end

    trait :platform do
      after(:create) { |game| create(:game_platform, game: game) }
    end

    trait :genre do
      after(:create) { |game| create(:game_genre, game: game) }
    end

    trait :wikidata_id do
      wikidata_id { Faker::Number.number(6) }
    end

    trait :steam_app_id do
      steam_app_id { Faker::Number.number(5) }
    end

    trait :pcgamingwiki_id do
      pcgamingwiki_id { Faker::Lorem.words(3).join('_') }
    end

    factory :game_with_cover, traits: [:cover]
    factory :game_with_everything,
      traits: [
        :description,
        :cover,
        :series,
        :developer,
        :publisher,
        :engine,
        :platform,
        :genre,
        :wikidata_id,
        :steam_app_id,
        :pcgamingwiki_id
      ]
  end
end
