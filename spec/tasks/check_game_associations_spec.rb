# frozen_string_literal: true

require 'rails_helper'

# vglist:wikidata:check_game_associations (lib/tasks/wikidata_associations.rake)
# prints a CSV of game associations that Wikidata doesn't have.
RSpec.describe 'vglist:wikidata:check_game_associations', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:check_game_associations')
    Rake::Task['vglist:wikidata:check_game_associations'].reenable
    create(:game_platform, game: game, platform: platform)
    create(:game_genre, game: game, genre: genre)
    allow(WikidataSparql).to receive(:query).and_return([value_row(100, 'P400', 501), value_row(100, 'P136', 601)])
  end

  # Returns the CSV the task writes to stdout, discarding the progress bar and
  # summary on stderr.
  def run_task
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    Rake::Task['vglist:wikidata:check_game_associations'].invoke
    $stdout.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def value_row(item, property, value)
    { item: "http://www.wikidata.org/entity/Q#{item}", property: property, value: "http://www.wikidata.org/entity/Q#{value}" }
  end

  let(:game) { create(:game, name: 'Doom, The', wikidata_id: 100) }
  let(:platform) { create(:platform, name: 'Wrong', wikidata_id: 500) }
  let(:genre) { create(:genre, name: 'Shooter', wikidata_id: 600) }

  it 'prints associations Wikidata does not have as CSV and leaves them alone' do
    expect(run_task.lines(chomp: true)).to eq(
      [
        'association,game_id,game_name,game_wikidata_id,record_id,record_name,record_wikidata_id,wikidata_values',
        "platforms,#{game.id},\"Doom, The\",100,#{platform.id},Wrong,500,1",
        "genres,#{game.id},\"Doom, The\",100,#{genre.id},Shooter,600,1"
      ]
    )
    expect(game.platforms.pluck(:id)).to eq([platform.id])
  end

  it 'limits the check to ASSOCIATIONS' do
    rows = with_environment('ASSOCIATIONS' => 'genres') { run_task }.lines(chomp: true).drop(1)

    expect(rows.map { |row| row.split(',').first }).to eq(['genres'])
  end
end
