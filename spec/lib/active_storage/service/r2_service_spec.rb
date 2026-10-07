# frozen_string_literal: true

require 'rails_helper'
require 'active_storage/service/r2_service'

RSpec.describe ActiveStorage::Service::R2Service do
  let(:config) do
    {
      r2: {
        service: 'R2',
        access_key_id: 'test-key',
        secret_access_key: 'test-secret',
        endpoint: 'https://example-account.r2.cloudflarestorage.com',
        region: 'auto',
        bucket: 'vglist-test-bucket',
        public: true,
        public_host: 'https://files.example.com/'
      }
    }
  end

  let(:service) { ActiveStorage::Service.configure(:r2, config) }

  it 'resolves from a storage.yml-style configuration' do
    expect(service).to be_a(described_class)
  end

  it 'builds public URLs from the custom domain rather than the S3 endpoint' do
    expect(service.url('some-blob-key')).to eq('https://files.example.com/some-blob-key')
  end

  it 'does not send an ACL on uploads since R2 ignores S3 ACLs' do
    expect(service.upload_options).not_to have_key(:acl)
  end

  it 'uses path-style addressing against the account endpoint' do
    expect(service.client.client.config.force_path_style).to be(true)
  end

  it 'restricts request checksums to when_required for R2 compatibility' do
    expect(service.client.client.config.request_checksum_calculation).to eq('when_required')
  end

  it 'restricts response checksum validation to when_required for R2 compatibility' do
    expect(service.client.client.config.response_checksum_validation).to eq('when_required')
  end
end
