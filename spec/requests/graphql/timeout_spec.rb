# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL timeouts", type: :request do
  include EnvHelper

  let(:query) { '{ basicSiteStatistics { games } }' }

  def graphql(query)
    post graphql_path, params: { query: query }.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  def statement_timeout
    ActiveRecord::Base.lease_connection.select_value('SHOW statement_timeout')
  end

  it 'sets a statement timeout while executing and resets it afterwards' do
    timeout_during_request = nil
    allow(Game).to receive(:count) do
      timeout_during_request = statement_timeout
      0
    end
    default = statement_timeout

    graphql(query)

    expect(response).to have_http_status(:success)
    expect(timeout_during_request).to eq('10s')
    expect(statement_timeout).to eq(default)
  end

  it 'cancels a slow statement and returns a GraphQL error' do
    allow(Game).to receive(:count) { ActiveRecord::Base.lease_connection.execute('SELECT pg_sleep(1)') }

    with_environment('GRAPHQL_STATEMENT_TIMEOUT' => '50ms') do
      graphql(query)
    end

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['errors'].first['message']).to eq('This request took too long and was cancelled.')
  end
end
