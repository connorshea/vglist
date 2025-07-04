FactoryBot.define do
  factory :steam_blocklist do
    steam_app_id { rand(0..100_000) }
    name { Faker::Game.unique.title }
    user
  end
end
