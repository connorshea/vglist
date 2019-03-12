FactoryBot.define do
  factory :game_purchase do
    game
    user

    trait :with_comments do
      comments { "I own this game" }
    end

    trait :with_rating do
      rating { rand(0..100) }
    end

    trait :with_completion_status do
      completion_status { rand(0..5) }
    end

    trait :with_start_date do
      start_date { 3.days.ago }
    end

    trait :with_completion_date do
      completion_date { 1.day.ago }
    end

    factory :game_purchase_with_comments_and_rating,
      traits: [:with_comments, :with_rating]
    factory :game_purchase_with_comments, traits: [:with_comments]
    factory :game_purchase_with_rating, traits: [:with_rating]
    factory :game_purchase_with_completion_status, traits: [:with_completion_status]

    factory :game_purchase_with_start_date, traits: [:with_start_date]
    factory :game_purchase_with_completion_date, traits: [:with_completion_date]
    factory :game_purchase_with_start_and_completion_dates, traits: [:with_start_date, :with_completion_date]
  end
end
