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
        public_host: 'https://files.example.com/',
        upload: {
          cache_control: 'public, max-age=31536000, immutable'
        }
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

  describe 'direct uploads' do
    let(:checksum) { Digest::MD5.base64digest('hello') }
    let(:url) do
      service.url_for_direct_upload(
        'some-blob-key',
        expires_in: 5.minutes,
        content_type: 'image/png',
        content_length: 5,
        checksum: checksum
      )
    end
    let(:headers) do
      service.headers_for_direct_upload(
        'some-blob-key',
        content_type: 'image/png',
        checksum: checksum,
        filename: ActiveStorage::Filename.new('cover.png')
      )
    end

    it 'presigns against the S3 API endpoint with path-style addressing' do
      expect(url).to start_with('https://example-account.r2.cloudflarestorage.com/vglist-test-bucket/some-blob-key?')
    end

    it 'tells the browser to send Cache-Control, which the presigned URL leaves unsigned' do
      signed_headers = Rack::Utils.parse_query(URI.parse(url).query)['X-Amz-SignedHeaders'].split(';')

      expect(signed_headers).not_to include('cache-control')
      expect(headers).to include('Cache-Control' => 'public, max-age=31536000, immutable')
    end
  end
end
