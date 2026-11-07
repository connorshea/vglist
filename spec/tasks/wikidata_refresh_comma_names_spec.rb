# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'vglist:wikidata:refresh_comma_names', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:refresh_comma_names')
    Rake::Task['vglist:wikidata:refresh_comma_names'].reenable
  end

  # The task logs with `puts`; capture it so specs can check what it reports.
  def run_task(env = {})
    original_stdout = $stdout
    original_env = env.keys.index_with { |key| ENV.fetch(key, nil) }
    $stdout = StringIO.new
    ENV.update(env)
    Rake::Task['vglist:wikidata:refresh_comma_names'].invoke
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

  it 'renames games whose Wikidata label differs and logs the changes' do
    game = create(:game, name: 'Turn, The', wikidata_id: 126_187_255)
    stub_labels(126_187_255 => 'The Turn')

    output = run_task

    expect(game.reload.name).to eq('The Turn')
    expect(output).to include(%(Renamed game #{game.id} (Q126187255): "Turn, The" -> "The Turn"))
    expect(output).to include('Renamed: 1, unchanged: 0')
  end

  it 'only reports changes in a dry run' do
    game = create(:game, name: 'Turn, The', wikidata_id: 1)
    stub_labels(1 => 'The Turn')

    output = run_task('DRY_RUN' => '1')

    expect(game.reload.name).to eq('Turn, The')
    expect(output).to include('[DRY RUN]').and include('Would rename game')
  end

  it 'lists games whose Wikidata label is still inverted' do
    game = create(:game, name: 'Ranch, A', wikidata_id: 1)
    stub_labels(1 => 'Ranch, A')

    output = run_task

    expect(output).to include('1 games still have an inverted name')
    expect(output).to include("game #{game.id}: https://www.wikidata.org/wiki/Q1")
  end

  it 'respects MIN_ID and MAX_ID' do
    included = create(:game, name: 'Turn, The', wikidata_id: 1)
    excluded = create(:game, name: 'Ranch, A', wikidata_id: 2)
    stub_labels(1 => 'The Turn', 2 => 'A Ranch')

    run_task('MIN_ID' => included.id.to_s, 'MAX_ID' => included.id.to_s)

    expect(included.reload.name).to eq('The Turn')
    expect(excluded.reload.name).to eq('Ranch, A')
  end

  it 'does nothing without matching games' do
    create(:game, name: 'The Turn', wikidata_id: 1)
    allow(WikidataSparql).to receive(:query)

    expect(run_task).to include('Checking 0 games')
    expect(WikidataSparql).not_to have_received(:query)
  end
end
