# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GraphqlTimeoutReport do
  let(:query) { GraphQL::Query.new(VideoGameListSchema, 'query SlowGame { currentUser { id } }') }

  before(:each) do
    allow(Sentry).to receive(:capture_exception)
    allow(Sentry).to receive(:capture_message)
  end

  it 'sends at most one event per request', :aggregate_failures do
    # One slow request can cancel several statements, one per field.
    2.times do
      described_class.capture(query, kind: :statement_timeout, message: 'Statement cancelled', exception: StandardError.new)
    end
    described_class.capture(query, kind: :query_timeout, message: 'Timeout on Query.currentUser')

    expect(Sentry).to have_received(:capture_exception).once
    expect(Sentry).not_to have_received(:capture_message)
  end

  it 'does nothing without a query' do
    described_class.capture(nil, kind: :statement_timeout, message: 'Statement cancelled')

    expect(Sentry).not_to have_received(:capture_message)
  end
end
