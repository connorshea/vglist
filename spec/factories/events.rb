# typed: false
FactoryBot.define do
  factory :event do
    user
    add_to_library

    trait :for_favorite_game do
      association(:eventable, factory: :favorite_game)
      event_category { :favorite_game }
    end

    trait :for_new_user do
      association(:eventable, factory: :user)
      event_category { :new_user }
    end

    trait :for_following do
      association(:eventable, factory: :relationship)
      event_category { :following }
    end

    trait :add_to_library do
      association(:eventable, factory: :game_purchase)
      event_category { :add_to_library }
    end

    trait :change_completion_status do
      association(:eventable, factory: :game_purchase)
      event_category { :change_completion_status }
      differences do
        # Pick two random values
        { completion_status: GamePurchase.completion_statuses.values.sample(2) }
      end
    end

    factory :game_purchase_library_event,    traits: [:add_to_library]
    factory :game_purchase_completion_event, traits: [:change_completion_status]
    factory :favorite_game_event,            traits: [:for_favorite_game]
    factory :new_user_event,                 traits: [:for_new_user]
    factory :following_event,                traits: [:for_following]
  end
end
