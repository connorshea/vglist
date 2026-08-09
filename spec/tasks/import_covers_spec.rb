# frozen_string_literal: true

require 'rails_helper'
require 'socket'

# The cover URL these tasks download comes out of an upstream API response
# rather than from the operator running the task, and PCGamingWiki is a wiki
# anyone can edit, so it has to be treated as attacker-controlled. See
# RemoteImageFetcher for the checks applied to it.
RSpec.describe 'import:pcgamingwiki:covers', type: :task do
  # A 1x1 PNG, so the attached bytes are a real image.
  let(:png) do
    [137, 80, 78, 71, 13, 10, 26, 10].pack('C*') +
      ['0000000d49484452000000010000000108060000001f15c489' \
       '0000000a49444154789c6360000002000100ffff03000006000557bfabd4' \
       '0000000049454e44ae426082'].pack('H*')
  end

  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:pcgamingwiki:covers')
    Rake::Task['import:pcgamingwiki:covers'].reenable
  end

  # Stand in for a PCGamingWiki page whose Cover URL an attacker has edited.
  def stub_upstream(cover_url)
    stub_request(:get, %r{www\.pcgamingwiki\.com/w/api\.php}).to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: { cargoquery: [{ title: { 'Cover URL' => cover_url } }] }.to_json
    )
  end

  # The task narrates itself with `puts` and a progress bar; keep that out of
  # the spec output.
  def run_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['import:pcgamingwiki:covers'].invoke
  ensure
    $stdout = original
  end

  it 'does not request an internal URL supplied by the upstream response' do
    # A stand-in for a service inside the deployment network that the internet
    # can't reach — a metadata endpoint, an admin port, an internal API.
    requests = []
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    listener = Thread.new do
      loop do
        connection = server.accept
        requests << connection.gets.to_s.strip
        connection.print("HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        connection.close
      end
    end

    create(:game, pcgamingwiki_id: 'Some_Game')
    stub_upstream("http://127.0.0.1:#{port}/latest/meta-data/iam/security-credentials")

    run_task

    # Give the listener a moment to record a request, so an unblocked fetch
    # can't pass by finishing after the assertion.
    sleep 0.3
    expect(requests).to be_empty
    expect(Game.joins(:cover_attachment).count).to eq(0)
  ensure
    listener&.kill
    server&.close
  end

  it 'attaches a cover from a public URL' do
    # Resolution is stubbed so the spec doesn't depend on DNS.
    allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.ip('93.184.216.34')])
    game = create(:game, pcgamingwiki_id: 'Some_Game')
    stub_upstream('https://images.pcgamingwiki.com/covers/half-life.png')
    stub_request(:get, 'https://images.pcgamingwiki.com/covers/half-life.png')
      .to_return(status: 200, body: png, headers: { 'Content-Type' => 'image/png' })

    run_task

    expect(game.reload.cover).to be_attached
    expect(game.cover.filename.to_s).to eq('half-life.png')
    expect(game.cover.byte_size).to eq(png.bytesize)
  end
end
