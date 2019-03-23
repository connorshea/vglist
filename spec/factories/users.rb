FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "johndoe#{n}@example.com" }
    password { "password" }
    sequence(:username) { |n| "johndoe#{n}" }
    bio { "My name is John Doe and I love video games." }

    trait :confirmed do
      after(:create) { |user| user.confirm }
    end

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(io: File.open(Rails.root.join('spec', 'factories', 'images', 'avatar.jpg')), filename: 'avatar.jpg', content_type: 'image/jpg')
      end
    end

    trait :with_game_purchase do
      after(:create) do |user|
        create :game_purchase, user: user
      end
    end

    trait :moderator do
      role { :moderator }
    end

    trait :admin do
      role { :admin }
    end

    factory :confirmed_user,                  traits: [:confirmed]
    factory :confirmed_user_with_avatar,      traits: [:confirmed, :with_avatar]

    factory :moderator,                       traits: [:moderator]
    factory :confirmed_moderator,             traits: [:confirmed, :moderator]
    factory :confirmed_moderator_with_avatar, traits: [:confirmed, :moderator, :with_avatar]

    factory :admin,                           traits: [:admin]
    factory :confirmed_admin,                 traits: [:confirmed, :admin]
    factory :confirmed_admin_with_avatar,     traits: [:confirmed, :admin, :with_avatar]

    factory :user_with_game_purchase,         traits: [:with_game_purchase]
  end
end
