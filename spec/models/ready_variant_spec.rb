# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReadyVariant do
  include ActiveJob::TestHelper

  # Created before clearing the jobs that attaching a cover queues.
  let!(:game) { create(:game, :cover) }

  before(:each) { clear_enqueued_jobs }

  it 'returns nil when nothing is attached' do
    expect(described_class.for(create(:game).cover, :small)).to be_nil
  end

  it 'returns the variant once it exists, without queueing anything' do
    game.cover.variant(:small).processed

    result = described_class.for(Game.find(game.id).cover, :small)

    expect(result).to be_a(ActiveStorage::VariantWithRecord)
    expect(result.variation.digest).to eq(game.cover.variant(:small).variation.digest)
    expect(ActiveStorage::TransformJob).not_to have_been_enqueued
  end

  it "returns the original and queues the variants when they don't exist yet" do
    result = nil

    expect { result = described_class.for(game.cover, :small) }
      .not_to change(ActiveStorage::VariantRecord, :count)

    expect(result).to eq(game.cover)
    expect(ActiveStorage::TransformJob).to have_been_enqueued.with(game.cover.blob, game.cover.variant(:small).variation.transformations)
  end
end
