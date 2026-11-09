# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessWarmup do
  before(:each) do
    # Disconnecting would end the example's transaction.
    allow(ActiveRecord::Base.connection_pool).to receive(:disconnect!)
  end

  it "loads each model's schema and attribute methods, then disconnects" do
    allow(Game).to receive(:load_schema).and_call_original
    allow(Game).to receive(:define_attribute_methods).and_call_original

    described_class.run

    expect(Game).to have_received(:load_schema)
    expect(Game).to have_received(:define_attribute_methods)
    expect(ActiveRecord::Base.connection_pool).to have_received(:disconnect!)
  end

  it 'logs instead of raising when it fails, and still disconnects' do
    allow(Game).to receive(:load_schema).and_raise(ActiveRecord::ConnectionNotEstablished, 'no database')
    allow(Rails.logger).to receive(:warn)

    expect { described_class.run }.not_to raise_error
    expect(Rails.logger).to have_received(:warn).with(/ProcessWarmup failed: ActiveRecord::ConnectionNotEstablished/)
    expect(ActiveRecord::Base.connection_pool).to have_received(:disconnect!)
  end

  it "only names operations the SPA sends" do
    expect(OperationAllowlist.operations.keys).to include(*described_class::QUERIES.keys)
  end

  describe '.run_queries' do
    let!(:game) { create(:game, :cover) }

    it 'runs each operation PASSES times without errors' do
      results = []
      allow(VideoGameListSchema).to receive(:execute).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap { |result| results << [kwargs[:operation_name], result] }
      end

      described_class.run_queries

      expect(results.map(&:first).tally).to eq(described_class::QUERIES.keys.index_with { described_class::PASSES })
      expect(results.filter_map { |_, result| result['errors'] }).to be_empty
      game_result = results.find { |name, _| name == 'GetGame' }.second
      expect(game_result.dig('data', 'game', 'id')).to eq(game.id.to_s)
    end

    it "skips GetGame when there's no game with a cover" do
      game.cover.purge
      allow(VideoGameListSchema).to receive(:execute).and_call_original

      described_class.run_queries

      expect(VideoGameListSchema).not_to have_received(:execute).with(anything, hash_including(operation_name: 'GetGame'))
    end

    it 'keeps going when an operation raises' do
      allow(VideoGameListSchema).to receive(:execute).and_call_original
      allow(VideoGameListSchema).to receive(:execute)
        .with(anything, hash_including(operation_name: 'GetHeroCovers'))
        .and_raise(ArgumentError, 'boom')
      allow(Rails.logger).to receive(:warn)

      described_class.run_queries

      expect(Rails.logger).to have_received(:warn).with('ProcessWarmup: GetHeroCovers failed: ArgumentError: boom').twice
      expect(VideoGameListSchema).to have_received(:execute)
        .with(anything, hash_including(operation_name: 'GetGame')).twice
    end

    it "doesn't queue jobs on the real adapter, and restores it afterwards" do
      adapter = ActiveJob::Base.queue_adapter
      # Attaching the factory's cover already queued analysis jobs.
      jobs_before = adapter.enqueued_jobs.size
      allow(VideoGameListSchema).to receive(:execute) do
        ActiveStorage::TransformJob.perform_later(game.cover.blob, {})
      end

      described_class.run_queries

      expect(ActiveJob::Base.queue_adapter).to equal(adapter)
      expect(adapter.enqueued_jobs.size).to eq(jobs_before)
    end

    it 'empties the cache, so the workers still queue missing variants' do
      allow(Rails.cache).to receive(:clear)

      described_class.run_queries

      expect(Rails.cache).to have_received(:clear)
    end
  end
end
