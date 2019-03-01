FactoryBot.define do
  factory :game_purchase do
    game
    user

    trait :with_comment do
      comment { "I own this game" }
    end

    trait :with_score do
      score { rand(0..100) }
    end

    factory :game_purchase_with_comment_and_score,
      traits: [:with_comment, :with_score]
    factory :game_purchase_with_comment, traits: [:with_comment]
    factory :game_purchase_with_score, traits: [:with_score]
  end
end
