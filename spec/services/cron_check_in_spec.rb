# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CronCheckIn do
  before(:each) do
    allow(Sentry).to receive(:capture_check_in).and_return('check-in-id')
  end

  it 'returns the block result and checks in as in_progress then ok' do
    result = described_class.wrap('update-stats', crontab: '0 0 * * *', max_runtime: 30) { :done }

    expect(result).to eq(:done)
    expect(Sentry).to have_received(:capture_check_in).with(
      'update-stats', :in_progress, monitor_config: an_instance_of(Sentry::Cron::MonitorConfig)
    ).ordered
    expect(Sentry).to have_received(:capture_check_in).with(
      'update-stats', :ok, hash_including(check_in_id: 'check-in-id', duration: a_kind_of(Float))
    ).ordered
  end

  it 'checks in as error and re-raises when the block raises' do
    expect do
      described_class.wrap('update-stats', crontab: '0 0 * * *', max_runtime: 30) { raise 'boom' }
    end.to raise_error(RuntimeError, 'boom')

    expect(Sentry).to have_received(:capture_check_in).with(
      'update-stats', :error, hash_including(check_in_id: 'check-in-id')
    )
  end

  it 'sends the schedule, margin and max runtime with the check-in' do
    described_class.wrap('update-stats', crontab: '0 0 * * *', max_runtime: 30) { nil }

    expect(Sentry).to have_received(:capture_check_in).with(
      'update-stats', :in_progress, monitor_config: having_attributes(
        timezone: 'UTC', checkin_margin: 15, max_runtime: 30
      )
    )
  end
end
