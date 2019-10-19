# typed: false
FactoryBot.define do
  factory :steam_app_id do
    game
    app_id { Faker::Number.unique.number(digits: 6) }
  end
end
