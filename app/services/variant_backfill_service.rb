# frozen_string_literal: true

# Creates the missing named variants of existing attachments, e.g. every
# game cover that doesn't have its small/medium/large sizes yet.
#
# This is much faster than calling `attachment.variant(name).processed` once
# per size, which is what Rails does on demand:
#
# - The original is downloaded once per image instead of once per size.
# - Variant blobs are saved with their width/height already filled in, so
#   attaching them doesn't queue an ActiveStorage::AnalyzeJob that downloads
#   each variant a second time.
# - `backfill` works on several images at once. Most of the time goes to
#   storage and database round trips, so a few threads go a long way without
#   adding much CPU load.
class VariantBackfillService
  # Errors caused by a bad or missing original. They're reported and skipped
  # rather than stopping a long backfill.
  SKIPPABLE_ERRORS = [
    Vips::Error,
    ActiveStorage::FileNotFoundError,
    ActiveStorage::IntegrityError
  ].freeze

  # Create the variants of `records` that don't exist yet.
  #
  # @param records [ActiveRecord::Relation] The records to backfill. Preload
  #   `<name>_attachment: { blob: :variant_records }` to avoid N+1 queries.
  # @param attachment_name [Symbol] e.g. `:cover`.
  # @param variant_names [Array<Symbol>] The named variants to create.
  # @param concurrency [Integer] How many images to work on at once. Capped
  #   so every worker thread can hold a database connection.
  # @param progress [#increment, nil] Incremented once per record.
  # @yieldparam record [ActiveRecord::Base] A record whose variants failed.
  # @yieldparam error [StandardError] One of SKIPPABLE_ERRORS.
  # @return [void]
  def self.backfill(records, attachment_name:, variant_names:, concurrency: 1, progress: nil, &on_error)
    # The main thread also holds a connection while it loads batches.
    concurrency = concurrency.clamp(1, [ActiveRecord::Base.connection_pool.size - 1, 1].max)
    # Bounded, so loading records never gets far ahead of the workers.
    queue = Thread::SizedQueue.new(concurrency * 2)
    lock = Mutex.new

    workers = Array.new(concurrency) do
      Thread.new do
        while (record = queue.pop)
          Rails.application.executor.wrap do
            new(record.public_send(attachment_name), variant_names).call
          rescue *SKIPPABLE_ERRORS => e
            lock.synchronize { on_error&.call(record, e) }
          end
          lock.synchronize { progress&.increment }
        end
      end
    end

    records.find_each(batch_size: 100) { |record| queue << record }
    queue.close
    workers.each(&:join)
  end

  # @param attached [ActiveStorage::Attached::One] e.g. `game.cover`.
  # @param variant_names [Array<Symbol>] The named variants to create.
  def initialize(attached, variant_names)
    @attached = attached
    @variant_names = variant_names
  end

  # Create the missing variants of this one attachment.
  #
  # @param original [File, Tempfile, nil] A local copy of the attached file,
  #   e.g. the download that was just attached. Saves fetching it back from
  #   storage. When nil, the original is downloaded.
  # @return [Integer] How many variants were created.
  def call(original: nil)
    return 0 unless @attached.attached? && @attached.variable?

    missing = missing_variations
    return 0 if missing.empty?

    if original
      transform(missing, original)
    else
      blob.open { |file| transform(missing, file) }
    end

    missing.size
  end

  private

  def transform(variations, original)
    variations.each do |variation|
      original.rewind
      variation.transform(original) { |output| create_variant_record(variation, output) }
    end
  end

  def blob
    @attached.blob
  end

  def missing_variations
    existing_digests = blob.variant_records.map(&:variation_digest)

    @variant_names.map { |name| @attached.variant(name).variation }
                  .reject { |variation| existing_digests.include?(variation.digest) }
  end

  # Mirrors ActiveStorage::VariantWithRecord#create_or_find_record, plus the
  # metadata that keeps the new blob from being analyzed again.
  def create_variant_record(variation, output)
    metadata = image_metadata(output)

    blob.variant_records.create_or_find_by!(variation_digest: variation.digest) do |record|
      record.image.attach(
        io: output,
        filename: "#{blob.filename.base}.#{variation.format.downcase}",
        content_type: variation.content_type,
        service_name: blob.service.name,
        metadata: metadata
      )
    end
  end

  # The same fields ActiveStorage's image analyzer would record. Reading the
  # header of the local file is cheap; downloading it again is not.
  def image_metadata(output)
    image = Vips::Image.new_from_file(output.path)
    { identified: true, analyzed: true, width: image.width, height: image.height }
  rescue Vips::Error
    { identified: true, analyzed: true }
  end
end
