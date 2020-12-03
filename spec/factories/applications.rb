# typed: false
FactoryBot.define do
  factory :application, class: 'OauthApplication' do
    name { Faker::Lorem.words(number: 3).join(' ') }
    confidential { false }
    owner_type { 'User' }
    association :owner, factory: :user
    redirect_uri { 'https://example.com/' }
    scopes { 'read write' }
    grant_flow { :authorization_code }

    trait :confidential do
      confidential { true }
    end

    trait :implicit_grant do
      grant_flow { :implicit }
    end
  end
end
