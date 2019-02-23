FactoryBot.define do
  factory :game do
    name { "Half-Life 2" }
    description { "A 2004 first-person shooter video game created by Valve." }

    trait :with_cover do
      after(:build) do |game|
        game.cover.attach(io: File.open(Rails.root.join('spec', 'factories', 'images', 'crysis.jpg')), filename: 'crysis.jpg', content_type: 'image/jpg')
      end
    end

    trait :with_series do
      series
    end

    trait :release_dates do
      release_dates do
        [
          {
            platform_id: "1",
            release_date: Faker::Date.between(20.years.ago, 1.year.from_now)
          }
        ]
      end
    end

    factory :game_with_cover, traits: [:with_cover]
    factory :game_with_series, traits: [:with_series]
    factory :game_with_release_dates, traits: [:release_dates]
  end
end
