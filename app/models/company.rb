# frozen_string_literal: true

class Company < ApplicationRecord
  include GlobalSearchable
  include Searchable
  include GameCountScopes

  has_many :game_developers, dependent: :destroy
  has_many :developed_games, through: :game_developers, source: :game

  has_many :game_publishers, dependent: :destroy
  has_many :published_games, through: :game_publishers, source: :game

  # games_count counts a game once even if the company both developed and
  # published it. See CompanyGamesCount.
  game_count_scopes 'companies.games_count'

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

  # Games this company developed or published.
  def games
    Game.where(id: game_developers.select(:game_id)).or(Game.where(id: game_publishers.select(:game_id)))
  end
end
