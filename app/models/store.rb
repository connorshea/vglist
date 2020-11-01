# typed: strict
class Store < ApplicationRecord
  include Searchable

  has_many :game_purchase_stores
  has_many :game_purchases, through: :game_purchase_stores, source: :game_purchase

  validates :name,
    presence: true,
    length: { maximum: 120 }

  searchable :name
end
