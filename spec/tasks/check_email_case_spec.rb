# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'vglist:users:check_email_case', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:users:check_email_case')
    Rake::Task['vglist:users:check_email_case'].reenable
  end

  def run_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['vglist:users:check_email_case'].invoke
    $stdout.string
  ensure
    $stdout = original
  end

  it 'reports OK when every email is normalized and unique' do
    create_list(:user, 2)

    expect(run_task).to include('OK: all emails are normalized and unique.')
  end

  it 'reports emails that are not normalized and case-insensitive duplicates', :aggregate_failures do
    lower = create(:user, email: 'dupe@example.com')
    # Skip Devise's downcasing to simulate rows written outside the model.
    upper = create(:user)
    # rubocop:disable Rails/SkipsModelValidations
    upper.update_column(:email, 'Dupe@Example.com')
    padded = create(:user)
    padded.update_column(:email, ' padded@example.com')
    # rubocop:enable Rails/SkipsModelValidations

    output = run_task

    expect(output).to include('Emails not stored lowercase/stripped: 2')
    expect(output).to include(%(user #{upper.id}: "Dupe@Example.com"))
    expect(output).to include(%(user #{padded.id}: " padded@example.com"))
    expect(output).to include('Case-insensitive duplicate groups: 1')
    expect(output).to include(%("dupe@example.com": user IDs #{[lower.id, upper.id].sort.join(', ')}))
    expect(output).to include('Needs cleanup')
  end
end
