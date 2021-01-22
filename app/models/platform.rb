# typed: strict
class Platform < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_platforms
  has_many :games, through: :game_platforms, source: :game

  has_many :game_purchase_platforms
  has_many :game_purchases, through: :game_purchase_platforms, source: :game_purchase

  has_paper_trail

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :wikidata_id,
    uniqueness: true,
    allow_blank: true,
    numericality: {
      only_integer: true,
      greater_than: 0
    }

  global_searchable :name
  searchable :name
end
