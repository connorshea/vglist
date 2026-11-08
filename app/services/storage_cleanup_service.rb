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
#
# It also finds variant records that the current size definitions never
# look up: covers and avatars resized under older definitions still have
# those variants, and nothing displays them.
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

  # Yields each variant record of a `model`'s `attachment_name` that isn't
  # one of its current `variant_names`, e.g. a cover size from before the
  # sizes were redefined. The app only ever looks variants up by name (see
  # ReadyVariant), so these are never shown.
  #
  # A variant's digest covers its transformations and output format, and the
  # format depends on each blob's filename, so the current digests are worked
  # out per image rather than once.
  #
  # @param model [Class<ActiveRecord::Base>] e.g. `Game`.
  # @param attachment_name [Symbol] e.g. `:cover`.
  # @param variant_names [Array<Symbol>] The named variants that are in use.
  # @yieldparam variant_record [ActiveStorage::VariantRecord]
  # @return [Enumerator] When no block is given.
  def self.each_stale_variant_record(model, attachment_name, variant_names)
    return enum_for(__method__, model, attachment_name, variant_names) unless block_given?

    records = model.joins(:"#{attachment_name}_attachment")
                   .preload("#{attachment_name}_attachment": { blob: { variant_records: { image_attachment: :blob } } })

    records.find_each do |record|
      attached = record.public_send(attachment_name)
      # Images that can't be resized (e.g. a GIF) are only ever shown as
      # the original, so any variants they have are unused.
      current = attached.variable? ? variant_names.to_set { |name| attached.variant(name).variation.digest } : Set.new

      attached.blob.variant_records.each do |variant_record|
        yield variant_record unless current.include?(variant_record.variation_digest)
      end
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
