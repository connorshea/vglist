# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sentry traces sampler' do # rubocop:disable RSpec/DescribeClass
  subject(:sampler) { SENTRY_TRACES_SAMPLER }

  it 'never traces the health check' do
    expect(sampler.call(env: { 'PATH_INFO' => '/health' }, parent_sampled: true)).to eq(0.0)
  end

  it "follows the frontend's decision when the request carries one" do
    expect(sampler.call(env: { 'PATH_INFO' => '/graphql' }, parent_sampled: true)).to eq(1.0)
    expect(sampler.call(env: { 'PATH_INFO' => '/graphql' }, parent_sampled: false)).to eq(0.0)
  end

  it 'samples requests without a frontend decision at the default rate' do
    expect(sampler.call(env: { 'PATH_INFO' => '/graphql' }, parent_sampled: nil)).to eq(SENTRY_TRACES_SAMPLE_RATE)
  end

  it 'samples background jobs, which have no Rack env, at the default rate' do
    expect(sampler.call(parent_sampled: nil)).to eq(SENTRY_TRACES_SAMPLE_RATE)
  end

  it 'defaults to 5%' do
    expect(SENTRY_TRACES_SAMPLE_RATE).to eq(0.05)
  end
end
