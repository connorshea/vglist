class Engine < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_engines
  has_many :games, through: :game_engines, source: :game

  has_paper_trail ignore: [:updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::EngineVersion'
                  }

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :wikidata_id,
    uniqueness: true,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than: 0
    }

  global_searchable :name
  searchable :name
end
