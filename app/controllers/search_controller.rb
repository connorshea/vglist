# typed: true
class SearchController < ApplicationController
  # Skip bullet on activity to avoid errors.
  around_action :skip_bullet, if: -> { defined?(Bullet) }

  def index
    skip_policy_scope

    # A list of the types of records which can be returned in the multisearch.
    # Intentionally ordered so the most important types come first.
    @searchable_types = %w[
      Game Series Company Platform Engine Genre User
    ]
    # Return only games if the `only_games` parameter is true.
    @searchable_types = ['Game'] if params[:only_games]

    @search_results = []
    # Return up to 15 records for each type of record and paginate if
    # necessary.
    @searchable_types.each do |searchable_type|
      @search_results << PgSearch.multisearch(params[:query])
                                 .where(searchable_type: searchable_type)
                                 .page(helpers.page_param)
                                 .per(15)
    end
    # Flatten search results so it returns the search results as one array
    # rather than as separate arrays.
    @search_results.flatten!
  end

  private

  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = previous_value
  end
end
