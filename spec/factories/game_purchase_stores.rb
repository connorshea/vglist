# frozen_string_literal: true

FactoryBot.define do
  factory :game_purchase_store do
    game_purchase
    store
  end
end
