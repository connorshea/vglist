# typed: false
FactoryBot.define do
  factory :event do
    user
    for_game_purchase

    trait :for_game_purchase do
      association(:eventable, factory: :game_purchase)

      # One of these needs to be included by default for the factory to be valid.
      # They can be overridden by explicitly using the traits for each event_type.
      event_category { [:add_to_library, :change_completion_status].sample }
    end

    trait :for_favorite_game do
      association(:eventable, factory: :favorite_game)
      event_category { :favorite_game }
    end

    trait :for_new_user do
      association(:eventable, factory: :user)
      event_category { :new_user }
    end

    trait :add_to_library do
      event_category { :add_to_library }
    end

    trait :change_completion_status do
      event_category { :change_completion_status }
      differences do
        # Pick two random values
        { completion_status: GamePurchase.completion_statuses.values.sample(2) }
      end
    end

    factory :game_purchase_event,            traits: [:for_game_purchase]
    factory :game_purchase_library_event,    traits: [:for_game_purchase, :add_to_library]
    factory :game_purchase_completion_event, traits: [:for_game_purchase, :change_completion_status]
    factory :favorite_game_event,            traits: [:for_favorite_game]
    factory :new_user_event,                 traits: [:for_new_user]
  end
end
