# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TurnstileVerifier do
  let(:siteverify_url) { 'https://challenges.cloudflare.com/turnstile/v0/siteverify' }

  def stub_siteverify(body, status: 200)
    stub_request(:post, siteverify_url).to_return(
      status: status,
      body: body.is_a?(String) ? body : body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  context 'when no secret key is configured' do
    around(:each) do |example|
      with_environment('TURNSTILE_SECRET_KEY' => nil) { example.run }
    end

    it 'is disabled' do
      expect(described_class.enabled?).to be(false)
    end

    it 'passes without calling Cloudflare' do
      expect(described_class.verify(token: nil)).to be(true)
      expect(a_request(:post, siteverify_url)).not_to have_been_made
    end
  end

  context 'when a secret key is configured' do
    # Cloudflare's dummy "always passes" secret key.
    around(:each) do |example|
      with_environment('TURNSTILE_SECRET_KEY' => '1x0000000000000000000000000000000AA') { example.run }
    end

    it 'is enabled' do
      expect(described_class.enabled?).to be(true)
    end

    it 'sends the secret, token and client IP, and passes on success', :aggregate_failures do
      stub_siteverify({ success: true })

      expect(described_class.verify(token: 'token', remote_ip: '203.0.113.7')).to be(true)
      expect(
        a_request(:post, siteverify_url).with(
          body: { secret: '1x0000000000000000000000000000000AA', response: 'token', remoteip: '203.0.113.7' }
        )
      ).to have_been_made.once
    end

    it 'leaves out the client IP when there is none' do
      stub_siteverify({ success: true })

      described_class.verify(token: 'token')
      expect(
        a_request(:post, siteverify_url).with(body: { secret: '1x0000000000000000000000000000000AA', response: 'token' })
      ).to have_been_made.once
    end

    it 'fails when Cloudflare rejects the token' do
      stub_siteverify({ success: false, 'error-codes' => ['invalid-input-response'] })

      expect(described_class.verify(token: 'token')).to be(false)
    end

    it 'fails without calling Cloudflare when the token is blank' do
      expect(described_class.verify(token: '')).to be(false)
      expect(a_request(:post, siteverify_url)).not_to have_been_made
    end

    it 'fails without calling Cloudflare when the token is too long' do
      expect(described_class.verify(token: 'a' * 2049)).to be(false)
      expect(a_request(:post, siteverify_url)).not_to have_been_made
    end

    it 'fails on an HTTP error' do
      stub_siteverify('oops', status: 500)

      expect(described_class.verify(token: 'token')).to be(false)
    end

    it 'fails on a malformed response' do
      stub_siteverify('not json')

      expect(described_class.verify(token: 'token')).to be(false)
    end

    it 'fails on a timeout' do
      stub_request(:post, siteverify_url).to_timeout

      expect(described_class.verify(token: 'token')).to be(false)
    end
  end
end
