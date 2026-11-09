# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessWarmup do
  before(:each) do
    # Disconnecting would end the example's transaction.
    allow(ActiveRecord::Base.connection_pool).to receive(:disconnect!)
  end

  it "loads each model's schema and attribute methods, then disconnects" do
    allow(Game).to receive(:load_schema).and_call_original
    allow(Game).to receive(:define_attribute_methods).and_call_original

    described_class.run

    expect(Game).to have_received(:load_schema)
    expect(Game).to have_received(:define_attribute_methods)
    expect(ActiveRecord::Base.connection_pool).to have_received(:disconnect!)
  end

  it 'logs instead of raising when it fails, and still disconnects' do
    allow(Game).to receive(:load_schema).and_raise(ActiveRecord::ConnectionNotEstablished, 'no database')
    allow(Rails.logger).to receive(:warn)

    expect { described_class.run }.not_to raise_error
    expect(Rails.logger).to have_received(:warn).with(/ProcessWarmup failed: ActiveRecord::ConnectionNotEstablished/)
    expect(ActiveRecord::Base.connection_pool).to have_received(:disconnect!)
  end
end
