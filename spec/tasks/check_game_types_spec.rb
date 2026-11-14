# frozen_string_literal: true

require 'rails_helper'

# vglist:wikidata:check_game_types (lib/tasks/wikidata_types.rake) prints a CSV
# of games whose Wikidata item is no longer an instance of a video game.
RSpec.describe 'vglist:wikidata:check_game_types', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:check_game_types')
    Rake::Task['vglist:wikidata:check_game_types'].reenable
  end

  # Returns the CSV the task writes to stdout, discarding the progress bar and
  # summary on stderr.
  def run_task
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    Rake::Task['vglist:wikidata:check_game_types'].invoke
    $stdout.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def class_row(wikidata_id, class_id, label)
    { item: "http://www.wikidata.org/entity/Q#{wikidata_id}", class: "http://www.wikidata.org/entity/Q#{class_id}", classLabel: label }
  end

  it 'prints games that are no longer video games as CSV and leaves them alone' do
    film = create(:game, name: 'Movie, The', wikidata_id: 100)
    create(:game, wikidata_id: 101)
    allow(WikidataSparql).to receive(:query).and_return([class_row(100, 11_424, 'film'), class_row(101, 7889, 'video game')])

    expect(run_task.lines(chomp: true)).to eq(
      [
        'kind,game_id,wikidata_id,game_name,owners,instance_of',
        "not_a_video_game,#{film.id},100,\"Movie, The\",0,Q11424 (film)"
      ]
    )
    expect(Game.exists?(film.id)).to be(true)
  end

  it 'limits the check to MIN_ID..MAX_ID' do
    games = Array.new(3) { |i| create(:game, wikidata_id: 100 + i) }
    allow(WikidataSparql).to receive(:query).and_return([])

    rows = with_environment('MIN_ID' => games[1].id.to_s, 'MAX_ID' => games[1].id.to_s) { run_task }.lines(chomp: true).drop(1)

    expect(rows.map { |row| row.split(',')[1].to_i }).to eq([games[1].id])
  end
end
