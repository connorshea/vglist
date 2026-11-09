# frozen_string_literal: true

# Work that every process would otherwise do on its first requests, done once
# in Puma's master process before it forks the workers (see config/puma.rb),
# so the workers inherit the results and their first requests don't pay for
# it.
#
# Eager loading loads the code, but each model still reads its columns from
# Postgres the first time it's used, one catalog query per table. A game page
# touches ~20 tables, so right after a deploy its first requests made ~50
# schema queries on top of their own, while also competing for CPU with the
# other worker doing the same.
#
# The code itself is cold too: YJIT compiles a method only after it has run
# a number of times, and graphql-ruby and Active Record fill caches on first
# use. So this also runs the queries behind the pages people land on. Locally,
# a forked child's first run of them took ~560 ms without this and ~195 ms
# with it. Right after a deploy, with both workers cold and sharing the CPU,
# the same requests took 7-16 s in production.
#
# Everything runs twice over: once as a signed-out visitor and once as a
# signed-in user. A signed-in request also resolves the user's avatar and
# checks each game against their library, and with only the signed-out run
# those were still cold: profiles of the slow requests after a deploy showed
# the time going to avatar URLs and library lookups.
module ProcessWarmup
  # Operations from the SPA's manifest (config/graphql/operations.json), with
  # the variables the SPA sends: the home page, the games index and a game
  # page (which loads its reviews and activity separately). A lambda is called
  # for variables that depend on the data, and may return nil to skip the
  # operation.
  GAME_ID = -> { Game.joins(:cover_attachment).order(:id).pick(:id)&.to_s }

  QUERIES = {
    'GetHeroCovers' => {},
    'GetBasicSiteStatistics' => {},
    'GetGamesIndexFilters' => {
      'platformId' => '0', 'hasPlatform' => false,
      'genreId' => '0', 'hasGenre' => false,
      'engineId' => '0', 'hasEngine' => false
    },
    'GetNewReleases' => { 'first' => 12 },
    'GetUpcomingReleases' => { 'first' => 6 },
    'GetGamesIndex' => { 'first' => 36, 'sortBy' => 'MOST_OWNERS', 'withCount' => true },
    'GetGame' => lambda {
      id = GAME_ID.call
      { 'id' => id } if id
    },
    'GetGameReviews' => lambda {
      id = GAME_ID.call
      { 'id' => id, 'sortBy' => 'RECENT', 'first' => 5 } if id
    },
    'GetGameActivity' => lambda {
      id = GAME_ID.call
      { 'id' => id, 'first' => 6 } if id
    }
  }.freeze

  # Operations only a signed-in session sends, run on top of QUERIES for the
  # signed-in user.
  SIGNED_IN_QUERIES = {
    'GetCurrentUserAvatar' => {}
  }.freeze

  # One pass leaves much of the code below YJIT's call threshold. Locally a
  # second pass cut the child's first requests from ~300 ms to ~195 ms and a
  # third didn't help.
  PASSES = 2

  module_function

  # Never raises: if this fails (say, the database is briefly unreachable),
  # the workers just do the work themselves, as they did before.
  def run
    load_model_schemas
    OperationAllowlist.canonical_documents if OperationAllowlist.enabled?
    run_queries
  rescue StandardError => e
    Rails.logger.warn("ProcessWarmup failed: #{e.class}: #{e.message}")
  ensure
    # Connections can't be shared with forked children. Rails would discard
    # them in each worker anyway, but don't leave them open in the master.
    ActiveRecord::Base.connection_pool.disconnect!
  end

  # Load every model's columns and define its attribute methods. Both are
  # stored on the model class, so forked workers keep them.
  def load_model_schemas
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      model.load_schema
      model.define_attribute_methods
    end
  end

  # Run QUERIES PASSES times signed out, and QUERIES plus SIGNED_IN_QUERIES
  # PASSES times as signed_in_user (when there is one). Results are thrown
  # away. An operation that raises is logged and skipped, so the rest still
  # run.
  def run_queries
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    queries = with_variables(QUERIES)
    user = signed_in_user
    signed_in_queries = user ? queries + with_variables(SIGNED_IN_QUERIES) : []

    without_jobs_or_cache do
      PASSES.times do
        queries.each { |name, variables| execute(name, variables) }
        signed_in_queries.each { |name, variables| execute(name, variables, current_user: user) }
      end
    end

    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    count = queries.size + signed_in_queries.size
    Rails.logger.info("ProcessWarmup ran #{count} GraphQL operations #{PASSES}x in #{elapsed_ms}ms")
  end

  # @return [Array<Array(String, Hash)>] Each operation with its variables,
  #   without the ones whose lambda returned nil.
  def with_variables(queries)
    queries.filter_map do |name, variables|
      variables = variables.call if variables.respond_to?(:call)
      [name, variables] if variables
    end
  end

  # The user the signed-in run is made as: one with an avatar and a library,
  # so the avatar and in-library lookups have something to find. The queries
  # only read, and their results are thrown away.
  # @return [User, nil]
  def signed_in_user
    User.joins(:avatar_attachment)
        .where(banned: false)
        .where(GamePurchase.where('game_purchases.user_id = users.id').arel.exists)
        .order(:id)
        .first
  end

  def execute(name, variables, current_user: nil)
    VideoGameListSchema.execute(
      OperationAllowlist.operations.fetch(name),
      variables: variables,
      operation_name: name,
      context: { current_user: current_user }.compact
    )
  rescue StandardError => e
    Rails.logger.warn("ProcessWarmup: #{name} failed: #{e.class}: #{e.message}")
  end

  # A cover without its resized variant makes ReadyVariant queue a
  # TransformJob and remember that in Rails.cache. In the master, the job's
  # thread wouldn't survive the fork, but the cache entry would, so the
  # workers wouldn't queue it for an hour. So hold jobs in the test adapter
  # (which only records them) and empty the cache afterwards. The cache is
  # per process and empty before this runs.
  #
  # The URL options are only for the Disk service in development and tests,
  # which builds cover URLs from the request's host. R2's public URLs don't
  # use them, and the results are thrown away anyway.
  def without_jobs_or_cache(&)
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    ActiveStorage::Current.set(url_options: { host: 'localhost' }, &)
  ensure
    ActiveJob::Base.queue_adapter = adapter
    Rails.cache.clear
  end
end
