# typed: true
class AdminPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :nilable

  def initialize(user, _nilable)
    @user = user
  end

  def dashboard?
    statistics?
  end

  def statistics?
    user&.admin?
  end

  def wikidata_blocklist?
    user&.admin?
  end

  def remove_from_wikidata_blocklist?
    user&.admin?
  end

  def steam_blocklist?
    user&.admin?
  end

  def new_steam_blocklist?
    user&.admin?
  end

  def add_to_steam_blocklist?
    user&.admin?
  end

  def remove_from_steam_blocklist?
    user&.admin?
  end

  def games_without_wikidata_ids?
    user&.admin?
  end
end
