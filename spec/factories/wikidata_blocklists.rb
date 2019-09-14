# typed: false
FactoryBot.define do
  factory :wikidata_blocklist do
    wikidata_id { rand(0..100_000) }
    name { Faker::Game.unique.title }
    user
  end
end
