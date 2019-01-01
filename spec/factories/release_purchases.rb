FactoryBot.define do
  factory :release_purchase do
    comment { "I own this game" }
    release
    user
  end
end
