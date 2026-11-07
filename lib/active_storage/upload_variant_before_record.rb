module ActiveStorage
  # Uploads a new variant's file before saving the variant record that points
  # to it.
  #
  # Stock Rails saves the ActiveStorage::VariantRecord and its blob first, and
  # only uploads the file in an `after_commit` callback. In between, any other
  # request sees the record, renders the variant's public URL, and the browser
  # gets a 404 from R2. Cloudflare then caches that 404 (files.vglist.co caches
  # everything for a year), so the image stays broken even after the upload
  # finishes. Uploading an avatar hits this every time: the `preprocessed`
  # variant job runs while the redirect to the profile renders the navbar.
  #
  # Uploading first means a variant record only ever exists once its file does.
  module UploadVariantBeforeRecord
    # Create the variant record for `blob` and `variation_digest`, or find the
    # one another process created first.
    #
    # @param blob [ActiveStorage::Blob] The original.
    # @param variation_digest [String]
    # @param image [Hash] Arguments for ActiveStorage::Blob.create_and_upload!,
    #   e.g. `io:`, `filename:`, `content_type:` and `service_name:`.
    # @return [ActiveStorage::VariantRecord]
    def self.create_or_find_record(blob, variation_digest, image)
      ActiveRecord::Base.connected_to(role: ActiveRecord.writing_role) do
        variant_blob = ActiveStorage::Blob.create_and_upload!(**image)

        record = blob.variant_records.create_or_find_by!(variation_digest: variation_digest) do |new_record|
          new_record.image.attach(variant_blob)
        end

        # Another process created this variant first, so ours isn't needed.
        variant_blob.purge_later unless record.image.blob == variant_blob
        record
      end
    end

    private

    def create_or_find_record(image:)
      @record = UploadVariantBeforeRecord.create_or_find_record(blob, variation.digest, image)
    end
  end
end
