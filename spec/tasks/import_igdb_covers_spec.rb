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

  it "keeps importing when a cover's sizes can't be created" do
    games = Array.new(2) { |i| create(:game, igdb_id: "game-#{i}") }
    stub_igdb(games.map(&:igdb_id))
    stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/})
      .to_return(status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' })
    backfill = instance_double(VariantBackfillService)
    allow(backfill).to receive(:call).and_raise(Vips::Error, 'corrupt image')
    allow(VariantBackfillService).to receive(:new).and_return(backfill)

    expect { run_task }.not_to raise_error
    games.each { |game| expect(game.reload.cover).to be_attached }
  end

  context 'with the test job adapter' do
    around(:each) do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "doesn't enqueue TransformJobs for the sizes it creates itself, but still does for other attachments" do
      game = create(:game, igdb_id: 'game-0')
      stub_igdb([game.igdb_id])
      stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/})
        .to_return(status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' })

      expect { run_task }.not_to have_enqueued_job(ActiveStorage::TransformJob)
      expect(game.reload.cover).to be_attached

      other_game = create(:game)
      expect do
        other_game.cover.attach(io: StringIO.new(jpeg), filename: 'cover.jpg', content_type: 'image/jpeg')
      end.to have_enqueued_job(ActiveStorage::TransformJob).exactly(Game::COVER_SIZES.size).times
    end
  end

  it 'only asks IGDB about games that have an IGDB ID and no cover' do
    wanted = create(:game, igdb_id: 'no-cover')
    create(:game_with_cover, igdb_id: 'has-cover')
    create(:game, igdb_id: nil)
    stub_igdb([])

    run_task

    expect(WebMock).to(have_requested(:post, 'https://api.igdb.com/v4/games').with { |request| request.body.include?(%("#{wanted.igdb_id}")) && request.body.exclude?('has-cover') })
  end

  it 'skips a game deleted after the list of games was made' do
    games = Array.new(2) { |i| create(:game, igdb_id: "game-#{i}") }
    stub_igdb(games.map(&:igdb_id))
    stub_request(:get, %r{images\.igdb\.com/igdb/image/upload/t_1080p/})
      .to_return(status: 200, body: jpeg, headers: { 'Content-Type' => 'image/jpeg' })
    # Delete one game once IGDB has answered, before the download pass reaches it.
    deleted = games.first
    WebMock.after_request do |request, _response|
      deleted.destroy if request.uri.host == 'api.igdb.com' && Game.exists?(deleted.id)
    end

    run_task

    expect(games.last.reload.cover).to be_attached
  ensure
    WebMock.reset_callbacks
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
