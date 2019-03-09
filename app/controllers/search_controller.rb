class SearchController < ApplicationController
  def index
    skip_policy_scope
    @search_results = PgSearch.multisearch(params[:query]).limit(20)
  end
end
