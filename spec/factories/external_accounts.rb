FactoryBot.define do
  factory :external_account do
    user
    account_type { :steam }

    steam_id { rand(0..10_000_000_000) }
    steam_profile_url { 'https://steamcommunity.com/id/username/' }
  end
end
