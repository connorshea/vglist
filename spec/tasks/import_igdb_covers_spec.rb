# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'import:igdb:covers', type: :task do
  include EnvHelper

  # A real JPEG, so libvips can resize it into each cover size.
  let(:jpeg) { Vips::Image.black(40, 60).write_to_buffer('.jpg') }

  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:igdb:covers')
    Rake::Task['import:igdb:covers'].reenable
    allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.ip('93.184.216.34')])

    stub_request(:post, %r{id\.twitch\.tv/oauth2/token})
      .to_return(status: 200, body: { access_token: 'token' }.to_json)
  end

  def stub_igdb(slugs)
    stub_request(:post, 'https://api.igdb.com/v4/games').to_return(
      status: 200,
      body: slugs.map { |slug| { id: 1, slug: slug, cover: { url: "//images.igdb.com/igdb/image/upload/t_thumb/#{slug}.jpg" } } }.to_json
    )
  end

  def run_task
    original = $stdout
    $stdout = StringIO.new
    # Keep the pool as-is, so the task doesn't reconnect out from under the
    # spec's transaction.
    with_environment('CONCURRENCY' => '2') { Rake::Task['import:igdb:covers'].invoke }
  ensure
    $stdout = original
  end

  it 'attaches each cover with its dimensions and every size already created' do
    games = Array.new(3) { |i| create(:game, igdb_id: "game-#{i}") }
    stub_igdb(games.map(&:igdb_id))
    stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/})
      .to_return(status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' })

    run_task

    games.each do |game|
      cover = game.reload.cover
      expect(cover).to be_attached
      expect(cover.metadata).to include('width' => 40, 'height' => 60, 'analyzed' => true)
      expect(cover.blob.variant_records.count).to eq(Game::COVER_SIZES.size)
    end
  end

  # Touching the game rewrites every index on `games`, which made each save
  # slow in production.
  it "doesn't touch the game when attaching its cover" do
    game = create(:game, igdb_id: 'game-0', updated_at: 1.day.ago)
    stub_igdb([game.igdb_id])
    stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/})
      .to_return(status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' })

    expect { run_task }.not_to(change { game.reload.updated_at })
    expect(game.cover).to be_attached
  end

  it 'starts at most 4 cover downloads a second, across every worker' do
    games = Array.new(4) { |i| create(:game, igdb_id: "game-#{i}") }
    stub_igdb(games.map(&:igdb_id))
    started = []
    stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/}).to_return do
      started << Process.clock_gettime(Process::CLOCK_MONOTONIC)
      { status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' } }
    end

    run_task

    expect(started.size).to eq(4)
    started.sort.each_cons(2) do |earlier, later|
      expect(later - earlier).to be >= 0.24
    end
  end
end
