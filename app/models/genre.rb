# frozen_string_literal: true

class Genre < ApplicationRecord
  include GlobalSearchable
  include Searchable
  include GameCountScopes

  has_many :game_genres, dependent: :destroy
  has_many :games, through: :game_genres, source: :game

  # A counter cache kept up to date by GameGenre.
  game_count_scopes 'genres.games_count'

  has_paper_trail ignore: [:games_count, :updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::GenreVersion'
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
