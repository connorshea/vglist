# typed: false
class Engine < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_engines
  has_many :games, through: :game_engines, source: :game

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
