class Company < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_developers, dependent: :destroy
  has_many :developed_games, through: :game_developers, source: :game

  has_many :game_publishers, dependent: :destroy
  has_many :published_games, through: :game_publishers, source: :game

  has_paper_trail ignore: [:updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::CompanyVersion'
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
