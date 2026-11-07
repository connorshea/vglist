# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveStorage::UploadVariantBeforeRecord do
  let(:user) { create(:user_with_avatar) }
  let(:service) { user.avatar.blob.service }

  it 'uploads the variant file before its record exists' do
    records_at_upload = []
    allow(service).to receive(:upload).and_wrap_original do |original, *args, **kwargs|
      records_at_upload << ActiveStorage::VariantRecord.count
      original.call(*args, **kwargs)
    end

    variant = user.avatar.variant(:small).processed

    expect(records_at_upload).to eq([0])
    expect(service.exist?(variant.key)).to be(true)
  end

  it 'gives every variant URL a file' do
    variant = user.sized_avatar(:small)

    expect(variant.image.blob.service.exist?(variant.key)).to be(true)
  end

  describe '.create_or_find_record' do
    let(:blob) { user.avatar.blob }
    let(:variation) { user.avatar.variant(:small).variation }
    let(:image) do
      {
        io: File.open(Rails.root.join('spec/factories/images/crysis.jpg')),
        filename: 'crysis.jpg',
        content_type: 'image/jpeg',
        service_name: blob.service.name
      }
    end

    it 'returns the existing record, and removes its own upload, when another process won' do
      existing = user.avatar.variant(:small).processed.send(:record)

      record = nil
      expect do
        record = described_class.create_or_find_record(blob, variation.digest, image)
      end.to have_enqueued_job(ActiveStorage::PurgeJob)

      expect(record).to eq(existing)
      expect(blob.variant_records.count).to eq(1)
    end
  end
end
