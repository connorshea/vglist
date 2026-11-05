# frozen_string_literal: true

class Series < ApplicationRecord
  include GlobalSearchable
  include Searchable

  has_many :games, dependent: :nullify

  # Correlated subqueries rather than a join + GROUP BY, so the relation stays
  # ungrouped: it can still be filtered, `totalCount` is a plain count, and
  # each series row carries its own numbers.
  GAMES_COUNT_SQL = '(SELECT COUNT(*) FROM games WHERE games.series_id = series.id)'
  FIRST_RELEASE_YEAR_SQL = '(SELECT EXTRACT(YEAR FROM MIN(games.release_date))::integer FROM games WHERE games.series_id = series.id)'
  LAST_RELEASE_YEAR_SQL = '(SELECT EXTRACT(YEAR FROM MAX(games.release_date))::integer FROM games WHERE games.series_id = series.id)'

  # Loads each series' game count and release-year span in the same query as
  # the series, for lists that show them on every row. `SeriesType` falls back
  # to counting per record when these weren't selected.
  scope :with_game_stats, -> {
    select(
      'series.*',
      "#{GAMES_COUNT_SQL} AS games_count",
      "#{FIRST_RELEASE_YEAR_SQL} AS first_release_year",
      "#{LAST_RELEASE_YEAR_SQL} AS last_release_year"
    )
  }

  # Each order ends on the ID so that pagination is stable across ties.
  scope :most_games, -> { order(Arel.sql("#{GAMES_COUNT_SQL} DESC, series.id ASC")) }
  scope :alphabetical, -> { order(Arel.sql('LOWER(series.name) ASC, series.id ASC')) }
  scope :recently_added, -> { order(created_at: :desc, id: :desc) }

  # Case-insensitive substring match on the name, for filtering a list.
  scope :name_contains, ->(text) { where('series.name ILIKE ?', "%#{sanitize_sql_like(text)}%") }

  has_paper_trail ignore: [:updated_at, :created_at],
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
