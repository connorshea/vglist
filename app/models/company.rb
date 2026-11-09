# frozen_string_literal: true

class Company < ApplicationRecord
  include GlobalSearchable
  include Searchable
  include GameCountScopes

  has_many :game_developers, dependent: :destroy
  has_many :developed_games, through: :game_developers, source: :game

  has_many :game_publishers, dependent: :destroy
  has_many :published_games, through: :game_publishers, source: :game

  # A game counts once even if the company both developed and published it.
  game_count_scopes <<~SQL.squish, with_games_count: true
    (SELECT COUNT(*) FROM (
      SELECT game_id FROM game_developers WHERE game_developers.company_id = companies.id
      UNION
      SELECT game_id FROM game_publishers WHERE game_publishers.company_id = companies.id
    ) company_games)
  SQL

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
