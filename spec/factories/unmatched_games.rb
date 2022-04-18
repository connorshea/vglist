# typed: false
FactoryBot.define do
  factory :unmatched_game do
    association :user
    external_service_id { Faker::Number.unique.number(digits: 6).to_s }
    external_service_name { 'Steam' }
    name { Faker::Game.title }
  end
end
