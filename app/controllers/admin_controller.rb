# typed: false
class AdminController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy
  end

  def wikidata_blocklist
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @blocklist = WikidataBlocklist.all.page params[:page]
  end
end
