# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'active_storage:vglist:clean:stale_variants', type: :task do
  include EnvHelper

  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('active_storage:vglist:clean:stale_variants')
    Rake::Task['active_storage:vglist:clean:stale_variants'].reenable
  end

  def run_task(env = {})
    original = $stdout
    $stdout = StringIO.new
    with_environment({ 'CONCURRENCY' => '2' }.merge(env)) do
      Rake::Task['active_storage:vglist:clean:stale_variants'].invoke
    end
    $stdout.string
  ensure
    $stdout = original
  end

  # A cover with every current size, plus `stale_count` variants at sizes
  # that aren't used any more.
  def cover_with_stale_variants(stale_count)
    game = create(:game, :cover)
    Game::COVER_SIZES.each_key { |name| game.cover.variant(name).processed }
    stale_blobs = Array.new(stale_count) do |i|
      game.cover.variant(resize_to_limit: [10 + i, 10 + i]).processed.image.blob
    end
    [game, stale_blobs]
  end

  it 'removes every stale variant and its file, across several workers' do
    games_and_blobs = Array.new(2) { cover_with_stale_variants(3) }

    output = run_task

    games_and_blobs.each do |game, stale_blobs|
      expect(game.reload.cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size)
      # [blob row exists, file exists] for each stale variant.
      expect(stale_blobs.map { |blob| [ActiveStorage::Blob.exists?(blob.id), blob.service.exist?(blob.key)] })
        .to all(eq([false, false]))
    end
    expect(output).to include('Removed 6 stale game cover variants')
  end

  it 'only reports stale variants on a dry run' do
    game, stale_blobs = cover_with_stale_variants(2)

    output = run_task('DRY_RUN' => '1')

    expect(game.reload.cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size + 2)
    expect(stale_blobs.map { |blob| blob.service.exist?(blob.key) }).to all(be(true))
    expect(output).to include('Found 2 stale game cover variants')
  end
end
