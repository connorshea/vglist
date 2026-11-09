# frozen_string_literal: true

namespace 'active_storage:vglist:clean' do
  desc "Remove any attachments where the blob has a content type other than PNG or JPG."
  task bad_content_types: :environment do
    # Get blobs where the content type is an invalid type (e.g. webp) and
    # they're associated with an attachment somehow.
    # Ideally this should never happen, but somehow it occasionally does. Need
    # to investigate this more.
    blobs = ActiveStorage::Blob.joins(:attachments).where.not(content_type: ['image/png', 'image/jpeg'])

    puts "Found #{blobs.count} ActiveStorage::Blobs with a bad content type."

    blobs.each do |blob|
      # They should only have one each, but do all of them just in case
      blob.attachments.each do |attachment|
        case attachment.record_type
        when 'Game'
          Game.find(attachment.record_id).cover.purge
        when 'User'
          User.find(attachment.record_id).avatar.purge
        when 'ActiveStorage::VariantRecord'
          puts 'ActiveStorage::VariantRecord, this should not happen'
        else
          raise StandardError, "Invalid record type for attachment: #{attachment.record_type}."
        end
      end
    end

    puts "Purged all ActiveStorage::Blobs with a bad content type."
  end

  # Set DRY_RUN=1 to report what would be removed without removing anything.
  dry_run = -> { ENV['DRY_RUN'].present? }
  megabytes = ->(bytes) { bytes.to_i.fdiv(1_000_000).round(2) }

  desc "Remove attachments (and their files) whose game, user, or other record no longer exists."
  task orphan_attachments: :environment do
    StorageCleanupService.unknown_record_types.each do |type|
      puts "Skipping attachments for #{type}, which isn't a model in this app."
    end

    attachments = StorageCleanupService.orphan_attachments
    puts "Found #{attachments.count} ActiveStorage::Attachments whose record no longer exists."
    next if dry_run.call

    StorageCleanupService.with_inline_jobs { attachments.find_each(&:purge) }

    puts "Purged all orphan ActiveStorage::Attachments."
  end

  desc "Remove any blobs (and their files) without an associated attachment."
  task orphan_blobs: :environment do
    # Leaves out blobs from the last day, which may be uploads that are about
    # to be attached.
    orphan_blobs = StorageCleanupService.orphan_blobs

    puts "Found #{orphan_blobs.count} orphan ActiveStorage::Blobs, total size #{megabytes.call(orphan_blobs.sum(:byte_size))} MB."
    next if dry_run.call

    StorageCleanupService.with_inline_jobs { orphan_blobs.find_each(&:purge) }

    puts "Purged all orphan ActiveStorage::Blobs."
  end

  desc "Remove cover and avatar variants (and their files) that aren't one of the current sizes."
  #
  # Each removal is a few round trips to the database and R2 and hardly any
  # CPU, so several run at once. Set CONCURRENCY to change how many (default
  # 6). Safe to stop and re-run: removed variants stay removed, and the rest
  # are found again next time.
  #
  #   CONCURRENCY=8 bundle exec rake active_storage:vglist:clean:stale_variants
  task stale_variants: :environment do
    concurrency = ENV.fetch('CONCURRENCY', 6).to_i.clamp(1, 16)
    unless dry_run.call
      # Each worker holds a database connection, and so does the main thread
      # while it loads batches. The pool defaults to RAILS_MAX_THREADS, which
      # is sized for Puma.
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      ActiveRecord::Base.establish_connection(config.merge(pool: concurrency + 1)) if config.fetch(:pool, 5).to_i < concurrency + 1
    end

    [
      [Game, :cover, Game::COVER_SIZES.keys],
      [User, :avatar, User::AVATAR_SIZES.keys]
    ].each do |model, attachment_name, variant_names|
      label = "#{model.name.downcase} #{attachment_name}"
      count = 0
      bytes = 0
      failed = 0
      lock = Mutex.new
      # Bounded, so finding stale variants never gets far ahead of removing them.
      queue = Thread::SizedQueue.new(concurrency * 2)

      puts "Removing stale #{label} variants (#{concurrency} at a time)..." unless dry_run.call

      # Destroying a variant record purges its image, inline so the files
      # are gone before the task exits.
      StorageCleanupService.with_inline_jobs do
        workers = Array.new(dry_run.call ? 0 : concurrency) do
          Thread.new do
            while (variant_record = queue.pop)
              Rails.application.executor.wrap do
                size = variant_record.image.attached? ? variant_record.image.blob.byte_size : 0
                variant_record.destroy!
                lock.synchronize { bytes += size }
              rescue StandardError => e
                # Report it and carry on: a re-run will find it again.
                lock.synchronize do
                  failed += 1
                  puts "Failed to remove variant record #{variant_record.id}: #{e.class}: #{e.message}"
                end
              end

              lock.synchronize do
                count += 1
                puts "  #{count} removed so far..." if (count % 1000).zero?
              end
            end
          end
        end

        StorageCleanupService.each_stale_variant_record(model, attachment_name, variant_names) do |variant_record|
          if dry_run.call
            count += 1
            bytes += variant_record.image.blob.byte_size if variant_record.image.attached?
          else
            queue << variant_record
          end
        end

        queue.close
        workers.each(&:join)
      end

      if dry_run.call
        puts "Found #{count} stale #{label} variants, total size #{megabytes.call(bytes)} MB."
      else
        puts "Removed #{count - failed} stale #{label} variants, total size #{megabytes.call(bytes)} MB."
        puts "#{failed} couldn't be removed; run the task again to retry them." if failed.positive?
      end
    end
  end

  desc "Remove files in the storage bucket that no blob points to."
  task orphan_files: :environment do
    service = ActiveStorage::Blob.service
    unless service.respond_to?(:bucket)
      puts "The #{service.name} storage service isn't S3-compatible, nothing to do."
      next
    end

    puts "Checking every file in the #{service.bucket.name} bucket (#{service.name})..."
    count = 0
    bytes = 0
    prefixes = Hash.new(0)
    examples = []

    StorageCleanupService.each_orphan_file_batch(service.bucket.objects) do |orphans|
      count += orphans.size
      bytes += orphans.sum(&:size)
      orphans.each { |object| prefixes[object.key.include?('/') ? "#{object.key.split('/').first}/" : '(top level)'] += 1 }

      examples.concat(orphans.first(10 - examples.size).map(&:key))
      next if dry_run.call

      service.bucket.delete_objects(delete: { objects: orphans.map { |object| { key: object.key } }, quiet: true })
      print '.'
    end

    puts
    puts "#{dry_run.call ? 'Found' : 'Deleted'} #{count} files with no blob, total size #{megabytes.call(bytes)} MB."
    prefixes.sort_by { |_prefix, n| -n }.each { |prefix, n| puts "  #{prefix}: #{n}" }
    puts("Examples:", *examples.map { |key| "  #{key}" }) if dry_run.call && examples.any?
  end

  desc "Run all ActiveStorage cleaning tasks."
  task all: :environment do
    # Orphan attachments first: bad_content_types expects every attachment's
    # record to exist.
    Rake::Task['active_storage:vglist:clean:orphan_attachments'].invoke
    Rake::Task['active_storage:vglist:clean:bad_content_types'].invoke
    Rake::Task['active_storage:vglist:clean:stale_variants'].invoke
    Rake::Task['active_storage:vglist:clean:orphan_blobs'].invoke
    Rake::Task['active_storage:vglist:clean:orphan_files'].invoke
  end
end
