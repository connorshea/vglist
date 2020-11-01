# typed: false
class Platform < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_platforms
  has_many :games, through: :game_platforms, source: :game

  has_many :game_purchase_platforms
  has_many :game_purchases, through: :game_purchase_platforms, source: :game_purchase

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :wikidata_id,
    uniqueness: true,
    allow_nil: true,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }

  global_searchable :name
  searchable :name
end
