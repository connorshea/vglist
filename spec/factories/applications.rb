# typed: false
FactoryBot.define do
  factory :application, class: 'Doorkeeper::Application' do
    name { Faker::String.random }
    confidential { false }
    owner_type { 'User' }
    association :owner, factory: :user
    redirect_uri { 'https://example.com/' }
    scopes { 'read write' }
  end
end
