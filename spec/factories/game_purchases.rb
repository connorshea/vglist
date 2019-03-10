FactoryBot.define do
  factory :game_purchase do
    game
    user

    trait :with_comments do
      comments { "I own this game" }
    end

    trait :with_score do
      score { rand(0..100) }
    end

    factory :game_purchase_with_comments_and_score,
      traits: [:with_comments, :with_score]
    factory :game_purchase_with_comments, traits: [:with_comments]
    factory :game_purchase_with_score, traits: [:with_score]
  end
end
