# frozen_string_literal: true

require 'rails_helper'

# vglist:wikidata:check_game_names (lib/tasks/wikidata_names.rake) prints a CSV
# of games whose names differ from their Wikidata labels.
RSpec.describe 'vglist:wikidata:check_game_names', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:check_game_names')
    Rake::Task['vglist:wikidata:check_game_names'].reenable
  end

  # Returns the CSV the task writes to stdout, discarding the progress bar and
  # summary on stderr.
  def run_task
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    Rake::Task['vglist:wikidata:check_game_names'].invoke
    $stdout.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def label_row(wikidata_id, label)
    { item: "http://www.wikidata.org/entity/Q#{wikidata_id}", enLabel: label, mulLabel: nil }
  end

  it 'prints mismatches as CSV and leaves the games alone' do
    mismatched = create(:game, name: 'Turn, The', wikidata_id: 100)
    create(:game, name: 'Portal 2', wikidata_id: 101)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, 'The Turn'), label_row(101, 'Portal 2')])

    csv = CSV.parse(run_task, headers: true)

    expect(csv.map(&:to_h)).to eq(
      [
        {
          'kind' => 'mismatch',
          'game_id' => mismatched.id.to_s,
          'wikidata_id' => '100',
          'game_name' => 'Turn, The',
          'wikidata_label' => 'The Turn',
          'label_language' => 'en'
        }
      ]
    )
    expect(mismatched.reload.name).to eq('Turn, The')
  end

  it 'limits the check to MIN_ID..MAX_ID' do
    games = Array.new(3) { |i| create(:game, name: "Game #{i}", wikidata_id: 100 + i) }
    allow(WikidataSparql).to receive(:query) do |sparql|
      sparql.scan(/wd:Q(\d+)/).flatten.map { |id| label_row(id, 'Different') }
    end

    stub_const('ENV', ENV.to_h.merge('MIN_ID' => games[1].id.to_s, 'MAX_ID' => games[1].id.to_s))
    csv = CSV.parse(run_task, headers: true)

    expect(csv.pluck('game_id')).to eq([games[1].id.to_s])
  end
end
