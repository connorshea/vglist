# frozen_string_literal: true

require 'active_storage/service/s3_service'

module ActiveStorage
  # ActiveStorage service for Cloudflare R2, which is S3-compatible but
  # diverges from S3 in ways that matter here:
  #
  # - R2 rejects the streaming checksums that aws-sdk-s3 >= 1.178 sends by
  #   default, so checksum calculation/validation is restricted to
  #   "when_required".
  # - Objects aren't publicly reachable via the S3 API endpoint. Public access
  #   goes through the custom domain connected to the bucket, so public URLs
  #   are built from +public_host+ instead of asking the SDK.
  # - R2 ignores S3 ACLs, so the "public-read" ACL that the stock S3Service
  #   adds to uploads when `public: true` is stripped.
  #
  # Configured via the `r2` entry in config/storage.yml.
  class Service::R2Service < Service::S3Service
    attr_reader :public_host

    def initialize(public_host:, **options)
      super(
        force_path_style: true,
        request_checksum_calculation: 'when_required',
        response_checksum_validation: 'when_required',
        **options
      )
      @public_host = public_host.chomp('/')
      upload_options.delete(:acl)
    end

    private

    def public_url(key, **)
      "#{public_host}/#{key}"
    end
  end
end
