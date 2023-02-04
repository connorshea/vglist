# typed: false
FactoryBot.define do
  factory :user do
    # Exclude id 1 to prevent flaky tests involving the behavior where users
    # automatically follow the user with an ID of 1.
    id { Faker::Number.unique.between(from: 2, to: 100_000) }

    sequence(:email) { |n| "johndoe#{n}@example.com" }
    password { "password" }
    sequence(:username) { |n| "johndoe#{n}" }
    bio { "My name is John Doe and I love video games." }

    trait :confirmed do
      after(:create) { |user| user.confirm }
    end

    trait :avatar do
      after(:build) do |user|
        user.avatar.attach(io: File.open(Rails.root.join('spec/factories/images/avatar.jpg')), filename: 'avatar.jpg', content_type: 'image/jpeg')
      end
    end

    trait :game_purchase do
      after(:create) do |user|
        create :game_purchase_with_everything, user: user
      end
    end

    trait :external_account do
      after(:create) do |user|
        create :external_account, user: user
      end
    end

    trait :favorite_game do
      after(:create) do |user|
        create :favorite_game, user: user
      end
    end

    trait :application do
      after(:create) do |user|
        create :application, owner: user
      end
    end

    trait :moderator do
      role { :moderator }
    end

    trait :banned do
      banned { true }
    end

    trait :admin do
      role { :admin }
    end

    trait :private_account do
      privacy { :private_account }
    end

    trait :encrypted_api_token do
      encrypted_api_token { EncryptionService.encrypt(SecureRandom.alphanumeric(20)) }
    end

    factory :confirmed_user,                  traits: [:confirmed]
    factory :confirmed_user_with_avatar,      traits: [:confirmed, :avatar]
    factory :private_user,                    traits: [:confirmed, :private_account]

    factory :moderator,                       traits: [:moderator]
    factory :confirmed_moderator,             traits: [:confirmed, :moderator]
    factory :confirmed_moderator_with_avatar, traits: [:confirmed, :moderator, :avatar]

    factory :admin,                           traits: [:admin]
    factory :confirmed_admin,                 traits: [:confirmed, :admin]
    factory :confirmed_admin_with_avatar,     traits: [:confirmed, :admin, :avatar]

    factory :user_with_avatar,                traits: [:avatar]
    factory :user_with_game_purchase,         traits: [:game_purchase]
    factory :user_with_favorite_game,         traits: [:favorite_game]

    factory :user_with_application,           traits: [:confirmed, :application]

    factory :banned_user,                     traits: [:confirmed, :banned]
  end
end
