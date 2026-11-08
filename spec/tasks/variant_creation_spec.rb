# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'active_storage:vglist:variants:covers', type: :task do
  include EnvHelper

  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('active_storage:vglist:variants:covers')
    Rake::Task['active_storage:vglist:variants:covers'].reenable
  end

  def run_task
    original = $stdout
    $stdout = StringIO.new
    # Keep the pool as-is, so the task doesn't reconnect out from under the
    # spec's transaction.
    with_environment('CONCURRENCY' => '2') { Rake::Task['active_storage:vglist:variants:covers'].invoke }
  ensure
    $stdout = original
  end

  def current_digests(game)
    Game::COVER_SIZES.keys.map { |name| game.cover.variant(name).variation.digest }
  end

  it 'creates every size of a cover that has none' do
    game = create(:game, :cover)

    run_task

    expect(game.reload.cover.blob.variant_records.map(&:variation_digest)).to match_array(current_digests(game))
  end

  # Covers resized under older size definitions still have those variant
  # records. Counting them made the task think these covers were done.
  it 'creates the current sizes of a cover that only has stale variants' do
    game = create(:game, :cover)
    [[10, 10], [20, 20], [30, 30]].each { |size| game.cover.variant(resize_to_limit: size).processed }

    run_task

    expect(game.reload.cover.blob.variant_records.map(&:variation_digest)).to include(*current_digests(game))
  end

  it "doesn't download a cover that already has every size" do
    game = create(:game, :cover)
    Game::COVER_SIZES.each_key { |name| game.cover.variant(name).processed }
    expect_any_instance_of(ActiveStorage::Blob).not_to receive(:open) # rubocop:disable RSpec/AnyInstance

    run_task

    expect(game.reload.cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size)
  end
end
