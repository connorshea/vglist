# frozen_string_literal: true

# Finds Active Storage data that nothing uses any more, at each of the three
# levels it can be left behind:
#
# 1. Attachments whose record is gone, e.g. a game removed with `delete` or
#    raw SQL, so its `dependent: :purge_later` callback never ran.
# 2. Blobs with no attachment, e.g. the purge job for a destroyed game's cover
#    was lost when Puma restarted (the async adapter keeps jobs in memory).
# 3. Files in the storage bucket with no blob, e.g. pre-Rails 6.1
#    `variants/<key>/...` files that tracked variants no longer use.
class StorageCleanupService
  # Anything newer is left alone, so an upload that has created its blob and
  # file but hasn't been attached yet isn't mistaken for an orphan.
  GRACE_PERIOD = 1.day

  # How many keys to check against the database, and delete, at once. 1000 is
  # also the most an S3 DeleteObjects request accepts.
  BATCH_SIZE = 1000

  # @return [ActiveRecord::Relation<ActiveStorage::Attachment>] Attachments
  #   whose record no longer exists.
  def self.orphan_attachments
    scopes = known_record_types.map do |type|
      model = type.constantize
      ActiveStorage::Attachment.where(record_type: type)
                               .where.not(record_id: model.unscoped.select(model.primary_key))
    end

    scopes.reduce(:or) || ActiveStorage::Attachment.none
  end

  # @return [Array<String>] Attachment record types that aren't a model in
  #   this app. They're never treated as orphans, since there's no table to
  #   check them against.
  def self.unknown_record_types
    attachment_record_types.reject do |type|
      model = type.safe_constantize
      model.is_a?(Class) && model < ActiveRecord::Base
    end
  end

  # @param older_than [Time]
  # @return [ActiveRecord::Relation<ActiveStorage::Blob>] Blobs that nothing
  #   is attached to.
  def self.orphan_blobs(older_than: GRACE_PERIOD.ago)
    ActiveStorage::Blob.unattached.where(created_at: ...older_than)
  end

  # Yields the objects in `objects` that no blob points to, a batch at a time.
  #
  # @param objects [Enumerable<#key, #last_modified>] e.g. `bucket.objects`.
  # @param older_than [Time]
  # @yieldparam orphans [Array] The orphaned objects in one batch.
  # @return [void]
  def self.each_orphan_file_batch(objects, older_than: GRACE_PERIOD.ago)
    objects.each_slice(BATCH_SIZE) do |slice|
      candidates = slice.select { |object| object.last_modified < older_than }
      known_keys = ActiveStorage::Blob.where(key: candidates.map(&:key)).pluck(:key).to_set
      orphans = candidates.reject { |object| known_keys.include?(object.key) }

      yield orphans if orphans.any?
    end
  end

  # Run the block with Active Job set to perform jobs immediately.
  #
  # Purging a blob destroys its variant records, and each variant's own blob
  # is then purged by an ActiveStorage::PurgeJob. With the async adapter a
  # rake task can exit before those jobs run, leaving the variant files behind.
  def self.with_inline_jobs
    previous = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    yield
  ensure
    ActiveJob::Base.queue_adapter = previous
  end

  def self.attachment_record_types
    ActiveStorage::Attachment.distinct.pluck(:record_type)
  end
  private_class_method :attachment_record_types

  def self.known_record_types
    attachment_record_types - unknown_record_types
  end
  private_class_method :known_record_types
end
