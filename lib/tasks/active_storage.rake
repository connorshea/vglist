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
    # Leaves out blobs from the last day, which may be direct uploads that
    # are about to be attached.
    orphan_blobs = StorageCleanupService.orphan_blobs

    puts "Found #{orphan_blobs.count} orphan ActiveStorage::Blobs, total size #{megabytes.call(orphan_blobs.sum(:byte_size))} MB."
    next if dry_run.call

    StorageCleanupService.with_inline_jobs { orphan_blobs.find_each(&:purge) }

    puts "Purged all orphan ActiveStorage::Blobs."
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
    Rake::Task['active_storage:vglist:clean:orphan_blobs'].invoke
    Rake::Task['active_storage:vglist:clean:orphan_files'].invoke
  end
end
