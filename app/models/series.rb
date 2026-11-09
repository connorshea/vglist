# frozen_string_literal: true

class Series < ApplicationRecord
  include GlobalSearchable
  include Searchable
  include GameCountScopes

  has_many :games, dependent: :nullify

  FIRST_RELEASE_YEAR_SQL = '(SELECT EXTRACT(YEAR FROM MIN(games.release_date))::integer FROM games WHERE games.series_id = series.id)'
  LAST_RELEASE_YEAR_SQL = '(SELECT EXTRACT(YEAR FROM MAX(games.release_date))::integer FROM games WHERE games.series_id = series.id)'

  # A counter cache kept up to date by Game's belongs_to :series.
  game_count_scopes 'series.games_count'

  # Loads each series' release-year span in the same query as the series, for
  # lists that show it on every row. `SeriesType` falls back to looking it up
  # per record when these weren't selected. (The game count is a column.)
  scope :with_game_stats, -> {
    select(
      'series.*',
      "#{FIRST_RELEASE_YEAR_SQL} AS first_release_year",
      "#{LAST_RELEASE_YEAR_SQL} AS last_release_year"
    )
  }

  has_paper_trail ignore: [:games_count, :updated_at, :created_at],
                  versions: {
                    class_name: 'Versions::SeriesVersion'
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
