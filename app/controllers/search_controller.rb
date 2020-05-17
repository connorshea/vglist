# typed: true
class SearchController < ApplicationController
  def index
    skip_policy_scope
    @search_results = PgSearch.multisearch(params[:query]).limit(15)
    # A list of the types of records which can be returned in the multisearch.
    # Intentionally ordered so the most important types come first.
    @searchable_types = %w[
      Game Series Company Platform Engine Genre User
    ]
  end
end
