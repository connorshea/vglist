# typed: false
FactoryBot.define do
  factory :wikidata_blocklist do
    wikidata_id { rand(0..100_000) }
  end
end
