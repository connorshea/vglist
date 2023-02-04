# typed: false
FactoryBot.define do
  factory :game_purchase_library_event, class: 'Events::GamePurchaseEvent', aliases: [:event] do
    user
    association(:eventable, factory: :game_purchase)
    event_category { :add_to_library }
  end

  factory :game_purchase_completion_event, class: 'Events::GamePurchaseEvent' do
    user
    association(:eventable, factory: :game_purchase)
    event_category { :change_completion_status }
    differences do
      # Pick two random values
      { completion_status: GamePurchase.completion_statuses.values.sample(2) }
    end
  end

  factory :favorite_game_event, class: 'Events::FavoriteGameEvent' do
    user
    association(:eventable, factory: :favorite_game)
    event_category { :favorite_game }
  end

  factory :new_user_event, class: 'Events::UserEvent' do
    user
    association(:eventable, factory: :user)
    event_category { :new_user }
  end

  factory :following_event, class: 'Events::RelationshipEvent' do
    user
    association(:eventable, factory: :relationship)
    event_category { :following }
  end
end
