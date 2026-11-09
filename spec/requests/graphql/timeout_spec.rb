# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL timeouts", type: :request do
  include EnvHelper

  let(:query) { '{ basicSiteStatistics { games } }' }

  def graphql(query)
    post graphql_path, params: { query: query }.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  # Stand-in for a statement that runs past the statement timeout. The real
  # timeout is set per connection from config/database.yml, so lower it for
  # this test's transaction only.
  def make_game_count_slow
    allow(Game).to receive(:count) do
      connection = ActiveRecord::Base.lease_connection
      connection.execute("SET LOCAL statement_timeout = '50ms'")
      connection.execute('SELECT pg_sleep(1)')
    end
  end

  describe 'the statement timeout in config/database.yml' do
    def database_config(timeout)
      with_environment('DB_STATEMENT_TIMEOUT' => timeout) do
        Rails.application.config.database_configuration.fetch('test')
      end
    end

    it 'is set on each connection when DB_STATEMENT_TIMEOUT is set' do
      expect(database_config('10s')['variables']).to eq('statement_timeout' => '10s')
    end

    # Migrations, rake tasks and the console don't load config/puma.rb, so they
    # keep the server default. An empty `variables` would also break dbconsole.
    it 'is left out when DB_STATEMENT_TIMEOUT is unset' do
      expect(database_config(nil)).not_to have_key('variables')
    end
  end

  it 'cancels a slow statement and returns a GraphQL error' do
    make_game_count_slow

    graphql(query)

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['errors'].first['message']).to eq('This request took too long and was cancelled.')
  end

  describe 'reporting to Sentry' do
    # The tags and fingerprint of the scope each event was captured in.
    let(:captured) { [] }

    def record_capture(*args)
      scope = Sentry.get_current_scope
      captured << { args: args, tags: scope.tags, fingerprint: scope.fingerprint }
      nil
    end

    before(:each) do
      allow(Sentry).to receive(:capture_exception) { |*args, **kwargs| record_capture(*args, **kwargs) }
      allow(Sentry).to receive(:capture_message) { |*args, **kwargs| record_capture(*args, **kwargs) }
    end

    it 'reports a cancelled statement, grouped by operation', :aggregate_failures do
      make_game_count_slow

      graphql('query SlowStats { basicSiteStatistics { games } }')

      expect(captured.size).to eq(1)
      expect(captured.first[:args].first).to be_a(ActiveRecord::QueryCanceled)
      expect(captured.first[:tags]).to include(graphql_operation: 'SlowStats', graphql_timeout: 'statement_timeout')
      expect(captured.first[:fingerprint]).to eq(%w[graphql-timeout statement_timeout SlowStats])
    end

    it 'reports a query that runs past its time limit', :aggregate_failures do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(GraphQL::Schema::Timeout).to receive(:max_seconds).and_return(-1)
      # rubocop:enable RSpec/AnyInstance

      graphql(query)

      expect(captured.size).to eq(1)
      expect(captured.first[:args]).to eq(
        ['GraphQL anonymous timed out: Timeout on Query.basicSiteStatistics', { level: :warning }]
      )
      expect(captured.first[:fingerprint]).to eq(%w[graphql-timeout query_timeout anonymous])
    end

    it "doesn't report a request that finishes in time" do
      graphql(query)

      expect(captured).to be_empty
    end
  end

  it 'stops resolving fields once the whole request runs past its time limit', :aggregate_failures do
    # A deadline already in the past, so the first field resolved times out.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(GraphQL::Schema::Timeout).to receive(:max_seconds).and_return(-1)
    # rubocop:enable RSpec/AnyInstance
    allow(Game).to receive(:count).and_call_original

    graphql(query)

    expect(Game).not_to have_received(:count)
    expect(response.parsed_body['errors'].first['message']).to eq('Timeout on Query.basicSiteStatistics')
    expect(response.parsed_body['data']).to be_nil
  end

  it "doesn't apply the time limit to mutations", :aggregate_failures do
    # The same past deadline as above. QueryTimeout falls through to it for
    # queries, but a mutation has already made its changes by the time its
    # payload fields resolve, so it must not be cut off.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(GraphQL::Schema::Timeout).to receive(:max_seconds).and_return(-1)
    # rubocop:enable RSpec/AnyInstance

    graphql('mutation { signIn(email: "nobody@example.com", password: "wrong") { token errors } }')

    expect(response.parsed_body['errors']).to be_nil
    expect(response.parsed_body.dig('data', 'signIn', 'errors')).to eq(['Invalid email or password.'])
  end
end
