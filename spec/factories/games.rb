# typed: false
FactoryBot.define do
  factory :game do
    name { "Half-Life 2" }

    trait :cover do
      after(:build) do |game|
        game.cover.attach(io: File.open(Rails.root.join('spec/factories/images/crysis.jpg')), filename: 'crysis.jpg', content_type: 'image/jpg')
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
      wikidata_id { Faker::Number.number(digits: 6) }
    end

    trait :steam_app_id do
      after(:create) { |game| create(:steam_app_id, game: game) }
    end

    trait :pcgamingwiki_id do
      pcgamingwiki_id { Faker::Lorem.words(number: 3).join('_') }
    end

    trait :mobygames_id do
      mobygames_id { Faker::Lorem.words(number: 3).join('-') }
    end

    trait :giantbomb_id do
      giantbomb_id { "3030-#{Faker::Number.unique.number(digits: rand(1..4))}" }
    end

    trait :epic_games_store_id do
      epic_games_store_id { Faker::Lorem.words(number: rand(1..3)).map(&:downcase).join('-') }
    end

    trait :release_date do
      release_date { Faker::Date.between(from: 25.years.ago, to: 2.years.from_now) }
    end

    factory :game_with_cover, traits: [:cover]
    factory :game_with_release_date, traits: [:release_date]
    factory :game_with_everything,
      traits: [
        :cover,
        :series,
        :developer,
        :publisher,
        :engine,
        :platform,
        :genre,
        :wikidata_id,
        :steam_app_id,
        :pcgamingwiki_id,
        :mobygames_id,
        :giantbomb_id,
        :epic_games_store_id,
        :release_date
      ]
  end
end
