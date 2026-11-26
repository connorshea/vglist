# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackloggdImportJob, type: :job do
  let(:user) { create(:user) }
  let(:backloggd_import) { BackloggdImport.create!(user: user, username: 'Example') }
  let(:empty_page) { '<html><body></body></html>' }

  before(:each) do
    allow_any_instance_of(Backloggd::ListFetcher).to receive(:sleep) # rubocop:disable RSpec/AnyInstance
  end

  def stub_list(status, body, status_code: 200)
    stub_request(:get, "https://backloggd.com/u/Example/games/added/type:#{status}/").to_return(status: status_code, body: body)
  end

  def stub_lists(played:)
    stub_list('playing', empty_page)
    stub_list('played', played)
    stub_list('backlog', empty_page)
  end

  it 'imports the games and records the results' do
    hollow_knight = create(:game, igdb_id: 'hollow-knight')
    stub_lists(played: file_fixture('backloggd/games_backlog_last_page.html').read.sub('elden-ring', 'hollow-knight'))
    stub_request(:get, %r{type:played/\?page=}).to_return(body: empty_page)

    described_class.perform_now(backloggd_import.id)

    expect(backloggd_import.reload).to have_attributes(status: 'succeeded', added_game_ids: [hollow_knight.id], unmatched_games: [])
    expect(user.game_purchases.sole.game).to eq(hollow_knight)
  end

  it 'records the games it could not match' do
    stub_lists(played: file_fixture('backloggd/games_backlog_last_page.html').read)

    described_class.perform_now(backloggd_import.id)

    expect(backloggd_import.reload.unmatched_games).to eq([{ 'name' => 'Elden Ring', 'slug' => 'elden-ring' }])
  end

  it 'fails when the profile has no games' do
    stub_lists(played: empty_page)

    described_class.perform_now(backloggd_import.id)

    expect(backloggd_import.reload).to have_attributes(status: 'failed', error_message: a_string_including("Couldn't find any games"))
  end

  it 'fails with the reason when Backloggd blocks the request' do
    stub_list('playing', file_fixture('backloggd/anubis_challenge.html').read)

    described_class.perform_now(backloggd_import.id)

    expect(backloggd_import.reload).to have_attributes(status: 'failed', error_message: a_string_including("didn't let vglist"))
  end

  it 'fails when the user does not exist' do
    stub_list('playing', '', status_code: 404)

    described_class.perform_now(backloggd_import.id)

    expect(backloggd_import.reload.error_message).to include("Couldn't find a Backloggd user called Example")
  end

  it 'does nothing for an import that is not queued' do
    backloggd_import.update!(status: :succeeded)

    expect { described_class.perform_now(backloggd_import.id) }.not_to(change { backloggd_import.reload.updated_at })
  end
end
