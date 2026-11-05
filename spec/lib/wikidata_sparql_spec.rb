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
end
