# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Backloggd::ListFetcher, type: :service do
  let(:played_page) { file_fixture('backloggd/games_played_page_1.html').read }
  let(:last_page) { file_fixture('backloggd/games_backlog_last_page.html').read }
  let(:empty_page) { '<html><body><div id="game-lists"></div></body></html>' }
  let(:sleeps) { [] }
  let(:fetcher) { described_class.new('Example', sleeper: ->(seconds) { sleeps << seconds }) }

  def stub_list(status, body, page: nil, status_code: 200)
    url = "https://backloggd.com/u/Example/games/added/type:#{status}/"
    url += "?page=#{page}" if page
    stub_request(:get, url).to_return(status: status_code, body: body, headers: { 'Content-Type' => 'text/html' })
  end

  describe '.username_from' do
    it 'accepts a username, an @username or a profile URL' do
      expect(described_class.username_from(' Example ')).to eq('Example')
      expect(described_class.username_from('@Example')).to eq('Example')
      expect(described_class.username_from('https://backloggd.com/u/Example/games/')).to eq('Example')
    end

    it 'rejects anything else' do
      expect { described_class.username_from('../admin') }.to raise_error(described_class::InvalidUsernameError)
      expect { described_class.username_from('') }.to raise_error(described_class::InvalidUsernameError)
    end
  end

  describe '#entries' do
    it 'fetches every page of each list, pausing between requests' do
      stub_list('playing', empty_page)
      stub_list('played', played_page)
      stub_list('played', last_page, page: 2)
      stub_list('backlog', empty_page)

      entries = fetcher.entries

      expect(entries.map { |e| [e.slug, e.status] }).to eq(
        [
          ['hollow-knight', 'played'],
          ['the-witcher-3-wild-hunt', 'played'],
          ['some-obscure-game', 'played'],
          ['elden-ring', 'played']
        ]
      )
      expect(sleeps).to eq([1.0, 1.0, 1.0])
    end

    it 'sends an honest User-Agent' do
      stub_list('playing', empty_page)
      stub_list('played', empty_page)
      stub_list('backlog', empty_page)

      fetcher.entries

      expect(a_request(:get, /backloggd\.com/).with(headers: { 'User-Agent' => described_class::USER_AGENT })).to have_been_made.times(3)
    end

    it 'stops at the page cap' do
      stub_const("#{described_class}::MAX_PAGES_PER_STATUS", 2)
      stub_list('playing', played_page)
      stub_list('playing', played_page, page: 2)
      stub_list('played', empty_page)
      stub_list('backlog', empty_page)

      fetcher.entries

      expect(a_request(:get, /type:playing/)).to have_been_made.times(2)
    end

    it 'stops at an empty page even if it links to another' do
      stub_list('playing', played_page)
      stub_list('playing', "#{empty_page}<a rel=\"next\" href=\"?page=3\">Next</a>", page: 2)
      stub_list('played', empty_page)
      stub_list('backlog', empty_page)

      fetcher.entries

      expect(a_request(:get, /type:playing/)).to have_been_made.times(2)
    end

    it 'raises when the user does not exist' do
      stub_list('playing', 'Not found', status_code: 404)

      expect { fetcher.entries }.to raise_error(described_class::UserNotFoundError)
    end

    it 'raises on the bot check page' do
      stub_list('playing', file_fixture('backloggd/anubis_challenge.html').read)

      expect { fetcher.entries }.to raise_error(described_class::BlockedError)
    end

    it 'raises when Backloggd is rate limiting' do
      stub_list('playing', '', status_code: 429)

      expect { fetcher.entries }.to raise_error(described_class::RequestError)
    end

    it 'follows redirects within Backloggd only' do
      stub_request(:get, 'https://backloggd.com/u/Example/games/added/type:playing/')
        .to_return(status: 301, headers: { 'Location' => 'https://evil.example.com/' })

      expect { fetcher.entries }.to raise_error(described_class::RequestError, /unexpected/)
    end
  end
end
