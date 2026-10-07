# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Parameter filtering for logs" do
  def filtered_path(path)
    env = Rack::MockRequest.env_for(path)
    env['action_dispatch.parameter_filter'] = Rails.application.config.filter_parameters
    ActionDispatch::Request.new(env).filtered_path
  end

  [
    '/users/confirmation?confirmation_token=abc123',
    '/users/password/edit?reset_password_token=abc123',
    '/oauth/authorize?code=abc123',
    '/oauth/token?access_token=abc123',
    '/oauth/token?refresh_token=abc123',
    '/oauth/token?token=abc123'
  ].each do |path|
    it "filters #{path.split('?').last.split('=').first} from #{path.split('?').first}" do
      expect(filtered_path(path)).not_to include('abc123')
      expect(filtered_path(path)).to include('[FILTERED]')
    end
  end

  it "leaves unrelated params alone" do
    expect(filtered_path('/games?page=2')).to eq('/games?page=2')
  end
end
