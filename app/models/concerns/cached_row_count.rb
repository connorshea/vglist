# frozen_string_literal: true

# A cached count of every row in a model's table, for big tables whose total
# is shown often but doesn't need to be exact to the second, like the games
# index's game count.
#
# Postgres has no stored row count, so `SELECT COUNT(*)` reads the whole table
# (or its primary key index) every time. Caching it for a few minutes means one
# count per worker per EXPIRES_IN, rather than one per page view.
#
# Rails.cache is a per-process memory store, so a new or deleted record shows
# up in the count after at most EXPIRES_IN, at different moments in each Puma
# worker. The key is fixed per model, so it can't fill the store.
module CachedRowCount
  extend ActiveSupport::Concern

  EXPIRES_IN = 5.minutes

  class_methods do
    # @return [Integer] The number of rows in this model's table, as of at most
    #   EXPIRES_IN ago.
    def cached_row_count
      Rails.cache.fetch("row_count/#{table_name}", expires_in: EXPIRES_IN) { count }
    end
  end
end
