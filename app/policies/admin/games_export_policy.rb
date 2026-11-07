# frozen_string_literal: true

class Admin::GamesExportPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, _record)
    @user = user
  end

  def show?
    user&.admin? || false
  end
end
