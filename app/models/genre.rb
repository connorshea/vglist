# frozen_string_literal: true

class Genre < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :game_genres, dependent: :destroy
  has_many :games, through: :game_genres, source: :game

  # Sort by the number of games, most first. Ties are broken by ID so the order
  # is stable for cursor pagination.
  scope :most_games, -> {
    left_joins(:game_genres)
      .group(:id)
      .order(Arel.sql('count(game_genres.game_id) desc'), :id)
  }

  has_paper_trail ignore: [:updated_at, :created_at],
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
