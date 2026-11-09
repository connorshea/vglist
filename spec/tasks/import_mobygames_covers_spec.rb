# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'import:mobygames:covers', type: :task do
  # A 1x1 PNG, so the attached bytes are a real image.
  let(:png) do
    [137, 80, 78, 71, 13, 10, 26, 10].pack('C*') +
      ['0000000d49484452000000010000000108060000001f15c489' \
       '0000000a49444154789c6360000002000100ffff03000006000557bfabd4' \
       '0000000049454e44ae426082'].pack('H*')
  end

  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:mobygames:covers')
    Rake::Task['import:mobygames:covers'].reenable
    # The task sleeps between requests to stay under MobyGames' rate limit.
    allow(TOPLEVEL_BINDING.receiver).to receive(:sleep)
    # Resolution is stubbed so the spec doesn't depend on DNS.
    allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.ip('93.184.216.34')])
    stub_request(:get, %r{cdn\.mobygames\.com/covers/})
      .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })
  end

  # Answer each /games request with a game, and a cover, for every requested ID.
  def stub_mobygames
    stub_request(:get, %r{api\.mobygames\.com/v1/games}).to_return do |request|
      ids = URI.decode_www_form(request.uri.query).filter_map { |key, value| value.to_i if key == 'id' }
      games = ids.map { |id| { game_id: id, sample_cover: { image: "https://cdn.mobygames.com/covers/#{id}.png" } } }
      { status: 200, headers: { 'Content-Type' => 'application/json' }, body: { games: games }.to_json }
    end
  end

  # The task narrates itself with `puts` and a progress bar; keep that out of
  # the spec output.
  def run_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['import:mobygames:covers'].invoke
  ensure
    $stdout = original
  end

  it 'attaches covers to games across more than one batch' do
    stub_const('MOBYGAMES_GAME_ID_BATCH_SIZE', 1)
    games = [create(:game, mobygames_id: 101), create(:game, mobygames_id: 102)]
    stub_mobygames

    run_task

    expect(games.map { |game| game.reload.cover.attached? }).to eq([true, true])
    expect(WebMock).to have_requested(:get, %r{api\.mobygames\.com/v1/games}).twice
  end

  it 'only asks MobyGames about games that have a MobyGames ID and no cover' do
    create(:game, mobygames_id: 201)
    create(:game_with_cover, mobygames_id: 202)
    create(:game, mobygames_id: nil)
    stub_mobygames

    run_task

    expect(WebMock).to(have_requested(:get, %r{api\.mobygames\.com/v1/games}).with { |request| request.uri.query.include?('id=201') && request.uri.query.exclude?('id=202') })
  end
end
