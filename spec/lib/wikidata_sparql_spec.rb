# frozen_string_literal: true

require 'rails_helper'
require 'wikidata_sparql'

RSpec.describe WikidataSparql do
  describe '.with_retry' do
    # Keep the specs fast and quiet: don't actually back off, and swallow the
    # retry warnings.
    before(:each) do
      allow(described_class).to receive(:sleep)
      allow(described_class).to receive(:warn)
    end

    let(:busy_error) do
      SPARQL::Client::ClientError.new(
        '{ "exception": "The query was rejected because all 32 threads for processing queries were busy ' \
        'for more than 1000ms (see the runtime parameter `query-queue-max-wait`). Please retry later" }'
      )
    end
    let(:rate_limit_error) { SPARQL::Client::ClientError.new('<html><head><title>429 Too Many Requests</title>') }
    let(:other_error) { SPARQL::Client::ClientError.new('{ "exception": "Invalid SPARQL query" }') }

    # Yields a block that raises the given errors in order, then returns :ok.
    def failing_then_ok(*errors)
      calls = 0
      lambda do
        calls += 1
        raise errors[calls - 1] if calls <= errors.length

        :ok
      end
    end

    it 'returns the result without sleeping when the request succeeds' do
      expect(described_class.with_retry { :ok }).to eq(:ok)
      expect(described_class).not_to have_received(:sleep)
    end

    it 'retries a busy-server rejection with a longer backoff than a 429' do
      block = failing_then_ok(busy_error, busy_error)

      expect(described_class.with_retry(&block)).to eq(:ok)
      expect(described_class).to have_received(:sleep).with(15).ordered
      expect(described_class).to have_received(:sleep).with(30).ordered
    end

    it 'retries a 429 with the shorter rate-limit backoff' do
      block = failing_then_ok(rate_limit_error, rate_limit_error)

      expect(described_class.with_retry(&block)).to eq(:ok)
      expect(described_class).to have_received(:sleep).with(4).ordered
      expect(described_class).to have_received(:sleep).with(8).ordered
    end

    it 'gives up after max_attempts on a persistently busy server' do
      attempts = 0

      expect do
        described_class.with_retry(max_attempts: 3) do
          attempts += 1
          raise busy_error
        end
      end.to raise_error(SPARQL::Client::ClientError, /threads for processing queries were busy/)
      expect(attempts).to eq(3)
      expect(described_class).to have_received(:sleep).twice
    end

    it 'does not retry other client errors' do
      attempts = 0

      expect do
        described_class.with_retry do
          attempts += 1
          raise other_error
        end
      end.to raise_error(SPARQL::Client::ClientError, /Invalid SPARQL query/)
      expect(attempts).to eq(1)
      expect(described_class).not_to have_received(:sleep)
    end
  end

  describe '.user_agent' do
    around(:each) do |example|
      original = ENV.fetch('WIKIDATA_QUERY_USER_AGENT', nil)
      example.run
    ensure
      ENV['WIKIDATA_QUERY_USER_AGENT'] = original
    end

    it 'returns WIKIDATA_QUERY_USER_AGENT when set' do
      ENV['WIKIDATA_QUERY_USER_AGENT'] = 'test-agent'

      expect(described_class.user_agent).to eq('test-agent')
    end

    it 'raises a clear error when WIKIDATA_QUERY_USER_AGENT is blank' do
      ENV['WIKIDATA_QUERY_USER_AGENT'] = ' '

      expect { described_class.user_agent }
        .to raise_error(described_class::MissingUserAgentError, /WIKIDATA_QUERY_USER_AGENT is not set/)
    end
  end

  describe '.query' do
    around(:each) do |example|
      original = ENV.fetch('WIKIDATA_QUERY_USER_AGENT', nil)
      example.run
    ensure
      ENV['WIKIDATA_QUERY_USER_AGENT'] = original
    end

    before(:each) { allow(described_class).to receive(:sleep) }

    it 'sends the configured User-Agent over HTTP' do
      ENV['WIKIDATA_QUERY_USER_AGENT'] = 'test-agent'
      # Stub at the HTTP layer rather than SPARQL::Client.new: sparql-client
      # only recognizes a String 'User-Agent' key and silently replaces
      # anything else with its own default, so only the real request proves
      # which header goes out.
      request = stub_request(:post, described_class::ENDPOINT).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/sparql-results+json' },
        body: { head: { vars: ['s'] }, results: { bindings: [] } }.to_json
      )

      described_class.query('SELECT * WHERE { ?s ?p ?o } LIMIT 1')

      expect(request.with(headers: { 'User-Agent' => 'test-agent' })).to have_been_made.once
    end

    it 'fails before sending anything when WIKIDATA_QUERY_USER_AGENT is unset' do
      ENV.delete('WIKIDATA_QUERY_USER_AGENT')
      allow(SPARQL::Client).to receive(:new)

      expect { described_class.query('SELECT * WHERE { ?s ?p ?o } LIMIT 1') }
        .to raise_error(described_class::MissingUserAgentError)
      expect(SPARQL::Client).not_to have_received(:new)
      expect(described_class).not_to have_received(:sleep)
    end
  end
end
