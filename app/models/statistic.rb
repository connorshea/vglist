# typed: true
class Statistic < ApplicationRecord
  validates :users, numericality: true
  validates :games, numericality: true
  validates :platforms, numericality: true
  validates :series, numericality: true
  validates :engines, numericality: true
  validates :companies, numericality: true
  validates :genres, numericality: true
  validates :stores, numericality: true
  validates :events, numericality: true
  validates :game_purchases, numericality: true
  validates :relationships, numericality: true
  validates :games_with_covers, numericality: true
  validates :games_with_release_dates, numericality: true
  validates :banned_users, numericality: true
  validates :mobygames_ids, numericality: true
  validates :pcgamingwiki_ids, numericality: true
  validates :wikidata_ids, numericality: true
  validates :giantbomb_ids, numericality: true
  validates :steam_app_ids, numericality: true
  validates :epic_games_store_ids, numericality: true
  validates :gog_ids, numericality: true
end
