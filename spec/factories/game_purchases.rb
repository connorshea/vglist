FactoryBot.define do
  factory :game_purchase do
    comment { "I own this game" }
    game
    user
  end
end
