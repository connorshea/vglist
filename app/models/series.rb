# typed: strict
class Series < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :games

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
