# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'vglist:wikidata:refresh_parenthetical_names', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:refresh_parenthetical_names')
    Rake::Task['vglist:wikidata:refresh_parenthetical_names'].reenable
  end

  # The task logs with `puts`; capture it so specs can check what it reports.
  def run_task(env = {})
    original_stdout = $stdout
    original_env = env.keys.index_with { |key| ENV.fetch(key, nil) }
    $stdout = StringIO.new
    ENV.update(env)
    Rake::Task['vglist:wikidata:refresh_parenthetical_names'].invoke
    $stdout.string
  ensure
    $stdout = original_stdout
    original_env&.each { |key, value| ENV[key] = value }
  end

  # Plain hashes stand in for the RDF solutions WikidataSparql.query returns.
  def stub_labels(labels)
    rows = labels.map { |id, label| { item: "http://www.wikidata.org/entity/Q#{id}", label: label } }
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  it 'renames games and series whose Wikidata label differs and logs the changes' do
    game = create(:game, name: 'Doom (2016 video game)', wikidata_id: 20_311_154)
    series = create(:series, name: 'Doom (video game series)', wikidata_id: 1)
    stub_labels(20_311_154 => 'Doom', 1 => 'Doom')

    output = run_task

    expect([game.reload.name, series.reload.name]).to eq(%w[Doom Doom])
    expect(output).to include(%(Renamed game #{game.id} (Q20311154): "Doom (2016 video game)" -> "Doom"))
      .and include(%(Renamed series #{series.id} (Q1): "Doom (video game series)" -> "Doom"))
    expect(output).to include('Done with game. Renamed: 1, unchanged: 0').and include('Done with series. Renamed: 1, unchanged: 0')
  end

  it 'only reports changes in a dry run' do
    game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
    stub_labels(1 => 'Doom')

    output = run_task('DRY_RUN' => '1')

    expect(game.reload.name).to eq('Doom (video game)')
    expect(output).to include('[DRY RUN]').and include('Would rename game')
  end

  it 'reports records without a Wikidata ID' do
    game = create(:game, name: 'Ranch (game)', wikidata_id: nil)
    allow(WikidataSparql).to receive(:query)

    output = run_task

    expect(output).to include('1 game records were skipped because they have no Wikidata ID')
    expect(output).to include(%(game #{game.id}: "Ranch (game)"))
    expect(output).to include('no Wikidata ID: 1')
  end

  it 'lists records whose Wikidata label still has a parenthetical' do
    game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
    stub_labels(1 => 'Doom (video game)')

    output = run_task

    expect(output).to include('1 game records still have a parenthetical')
    expect(output).to include("game #{game.id}: https://www.wikidata.org/wiki/Q1")
  end

  it 'respects MIN_ID and MAX_ID' do
    included = create(:game, name: 'Doom (video game)', wikidata_id: 1)
    excluded = create(:game, name: 'Quake (video game)', wikidata_id: 2)
    stub_labels(1 => 'Doom', 2 => 'Quake')

    run_task('MIN_ID' => included.id.to_s, 'MAX_ID' => included.id.to_s, 'MODEL' => 'Game')

    expect(included.reload.name).to eq('Doom')
    expect(excluded.reload.name).to eq('Quake (video game)')
  end

  it 'only checks one model with MODEL' do
    game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
    series = create(:series, name: 'Doom (video game series)', wikidata_id: 2)
    stub_labels(1 => 'Doom', 2 => 'Doom')

    output = run_task('MODEL' => 'series')

    expect(series.reload.name).to eq('Doom')
    expect(game.reload.name).to eq('Doom (video game)')
    expect(output).not_to include('game records')
  end

  it 'does nothing without matching records' do
    create(:game, name: 'Doom', wikidata_id: 1)
    allow(WikidataSparql).to receive(:query)

    output = run_task

    expect(output).to include('Checking 0 game records').and include('Checking 0 series records')
    expect(WikidataSparql).not_to have_received(:query)
  end
end
