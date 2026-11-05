# frozen_string_literal: true

require 'rails_helper'
require 'ruby-progressbar'

RSpec.describe VariantBackfillService, type: :service do
  let(:sizes) { Game::COVER_SIZES.keys }

  describe '#call' do
    let!(:game) { create(:game, :cover) }

    it 'creates every missing variant' do
      expect(described_class.new(game.cover, sizes).call).to eq(sizes.size)
      expect(game.cover.blob.variant_records.count).to eq(sizes.size)
    end

    it 'creates the same variants Rails would' do
      described_class.new(game.cover, sizes).call

      digests = sizes.map { |size| game.cover.variant(size).variation.digest }
      expect(game.cover.blob.variant_records.reload.map(&:variation_digest)).to match_array(digests)
    end

    it 'downloads the original only once' do
      allow(game.cover.blob).to receive(:open).and_call_original

      described_class.new(game.cover, sizes).call

      expect(game.cover.blob).to have_received(:open).once
    end

    it 'skips variants that already exist' do
      game.sized_cover(:small)

      expect(described_class.new(game.reload.cover, sizes).call).to eq(sizes.size - 1)
      expect(described_class.new(game.reload.cover, sizes).call).to eq(0)
    end

    it 'stores dimensions on the variant blobs instead of analyzing them later' do
      expect { described_class.new(game.cover, sizes).call }
        .not_to have_enqueued_job(ActiveStorage::AnalyzeJob)

      small = game.reload.cover.variant(:small).image.blob
      expect(small.metadata).to include('analyzed' => true, 'width' => be_positive, 'height' => be_positive)
    end

    it 'does nothing without a cover' do
      expect(described_class.new(create(:game).cover, sizes).call).to eq(0)
    end
  end

  describe '.backfill' do
    let!(:games) { create_list(:game, 2, :cover) }

    # One worker: the specs share a single database connection between
    # threads, so concurrent transactions would interleave on it.
    it 'creates the variants for every record and reports progress' do
      progress = ProgressBar.create(total: games.size, output: StringIO.new)

      described_class.backfill(Game.where(id: games), attachment_name: :cover, variant_names: sizes, progress: progress)

      games.each { |game| expect(game.reload.cover.blob.variant_records.count).to eq(sizes.size) }
      expect(progress.progress).to eq(games.size)
    end

    it 'reports images that cannot be processed and carries on' do
      broken = games.first
      broken.cover.blob.service.delete(broken.cover.blob.key)
      failures = []

      described_class.backfill(Game.where(id: games), attachment_name: :cover, variant_names: sizes) do |record, error|
        failures << [record.id, error.class]
      end

      expect(failures).to eq([[broken.id, ActiveStorage::FileNotFoundError]])
      expect(games.last.reload.cover.blob.variant_records.count).to eq(sizes.size)
    end
  end
end
