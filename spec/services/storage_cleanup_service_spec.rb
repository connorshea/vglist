# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StorageCleanupService, type: :service do
  def upload_blob(created_at: 2.days.ago)
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('not attached'), filename: 'orphan.txt')
    blob.update!(created_at: created_at)
    blob
  end

  describe '.orphan_attachments' do
    let!(:game) { create(:game, :cover) }

    it 'finds attachments whose record was deleted without callbacks' do
      Game.where(id: game.id).delete_all

      expect(described_class.orphan_attachments).to contain_exactly(have_attributes(record_type: 'Game', record_id: game.id))
    end

    it 'leaves attachments of existing records alone' do
      create(:user, :avatar)
      game.cover.variant(:small).processed

      expect(described_class.orphan_attachments).to be_empty
    end

    it 'skips record types that are not models' do
      # Inserted directly: saving an attachment loads its record, and this
      # record type no longer exists.
      ActiveStorage::Attachment.insert_all!([{ name: 'cover', record_type: 'RemovedModel', record_id: 1, blob_id: upload_blob.id, created_at: Time.current }]) # rubocop:disable Rails/SkipsModelValidations

      expect(described_class.unknown_record_types).to eq(['RemovedModel'])
      expect(described_class.orphan_attachments).to be_empty
    end
  end

  describe '.orphan_blobs' do
    it 'finds blobs that nothing is attached to' do
      orphan = upload_blob
      create(:game, :cover).cover.blob.update!(created_at: 2.days.ago)

      expect(described_class.orphan_blobs).to contain_exactly(orphan)
    end

    it 'leaves recent uploads alone, since they may be about to be attached' do
      upload_blob(created_at: 1.hour.ago)

      expect(described_class.orphan_blobs).to be_empty
    end
  end

  describe '.each_orphan_file_batch' do
    let(:object) { Struct.new(:key, :last_modified) }

    it 'yields old files that no blob points to' do
      blob = upload_blob
      files = [
        object.new(blob.key, 2.days.ago),
        object.new('variants/abc/123', 2.days.ago),
        object.new('just-uploaded', 1.minute.ago)
      ]

      batches = []
      described_class.each_orphan_file_batch(files) { |orphans| batches << orphans.map(&:key) }

      expect(batches).to eq([['variants/abc/123']])
    end
  end

  describe '.each_stale_variant_record' do
    def stale_records
      described_class.each_stale_variant_record(Game, :cover, Game::COVER_SIZES.keys).to_a
    end

    it 'finds variants that are not one of the current sizes' do
      game = create(:game, :cover)
      current = game.cover.variant(:small).processed.send(:record)
      stale = game.cover.variant(resize_to_limit: [10, 10]).processed.send(:record)

      expect(stale_records).to contain_exactly(stale)
      expect(stale_records).not_to include(current)
    end

    it 'leaves a cover with only the current sizes alone' do
      game = create(:game, :cover)
      Game::COVER_SIZES.each_key { |name| game.cover.variant(name).processed }

      expect(stale_records).to be_empty
    end

    it "only looks at the given model's attachment" do
      user = create(:user, :avatar)
      user.avatar.variant(resize_to_fill: [10, 10]).processed

      expect(stale_records).to be_empty
      expect(described_class.each_stale_variant_record(User, :avatar, User::AVATAR_SIZES.keys).count).to eq(1)
    end

    it "removes a stale variant's file when it's destroyed" do
      game = create(:game, :cover)
      Game::COVER_SIZES.each_key { |name| game.cover.variant(name).processed }
      stale_blob = game.cover.variant(resize_to_limit: [10, 10]).processed.image.blob

      described_class.with_inline_jobs { stale_records.each(&:destroy!) }

      expect(stale_blob.service.exist?(stale_blob.key)).to be(false)
      expect(ActiveStorage::Blob.exists?(stale_blob.id)).to be(false)
      expect(game.reload.cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size)
    end
  end

  describe '.with_inline_jobs' do
    it "purges a deleted game's cover along with its variants' files" do
      game = create(:game, :cover)
      variant_blob = game.cover.variant(:small).processed.image.blob
      service = variant_blob.service
      Game.where(id: game.id).delete_all

      described_class.with_inline_jobs { described_class.orphan_attachments.find_each(&:purge) }

      expect(ActiveStorage::Blob.count).to eq(0)
      expect(service.exist?(variant_blob.key)).to be(false)
    end

    it 'restores the previous queue adapter' do
      expect { described_class.with_inline_jobs { nil } }.not_to(change { ActiveJob::Base.queue_adapter.class })
    end
  end
end
