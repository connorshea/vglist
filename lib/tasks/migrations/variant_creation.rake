# frozen_string_literal: true

# Creates the named variants (small/medium/large) for every existing game cover
# and user avatar that doesn't have them yet, so nobody has to wait for one to
# be generated mid-request. New uploads get theirs in the background, see the
# `preprocessed: true` variants on Game and User.
#
# Safe to stop and re-run: images that already have every variant are
# skipped (without downloading them), though the progress bar still counts
# them. Most of the time goes to downloading and uploading images, so it
# works on several at a time; set CONCURRENCY to change how many (default 6).
# The task gives itself a database pool big enough for that many threads, so
# it isn't capped by RAILS_MAX_THREADS (3 on App Platform). Each thread holds
# a database connection, so keep it well under the database's limit.
#
#   CONCURRENCY=6 bundle exec rake active_storage:vglist:variants:create
namespace 'active_storage:vglist:variants' do
  require 'ruby-progressbar'

  # Records of `model` whose `attachment_name` is a resizable image.
  #
  # This deliberately doesn't try to skip images that already have their
  # variants in SQL. Counting an image's variant records isn't enough: images
  # resized under older size definitions still have those stale records, so an
  # image can have three or more of them and none of the current sizes. Which
  # sizes are missing depends on each variation's digest, which includes the
  # output format derived from the blob's filename, so VariantBackfillService
  # works it out per image (from the preloaded records, without a download)
  # and skips the ones that are already complete.
  variable_attachments = lambda do |model, attachment_name|
    model.joins(:"#{attachment_name}_attachment")
         .joins("JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id")
         .where(active_storage_blobs: { content_type: ActiveStorage.variable_content_types })
         .preload("#{attachment_name}_attachment": { blob: :variant_records })
  end

  # The pool defaults to RAILS_MAX_THREADS, which is sized for Puma rather than
  # for this task. The worker threads and the main thread (which loads
  # batches) each need a connection.
  ensure_pool_size = lambda do |size|
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    return if config.fetch(:pool, 5).to_i >= size

    ActiveRecord::Base.establish_connection(config.merge(pool: size))
  end

  backfill = lambda do |model, attachment_name, variant_names|
    records = variable_attachments.call(model, attachment_name)
    concurrency = ENV.fetch('CONCURRENCY', 6).to_i.clamp(1, 16)
    ensure_pool_size.call(concurrency + 1)

    puts "Creating #{model.name.downcase} #{attachment_name} variants (#{concurrency} at a time)..."
    progress_bar = ProgressBar.create(
      total: records.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Disable logging in production to prevent log spam.
    Rails.logger.level = :error if Rails.env.production?

    VariantBackfillService.backfill(
      records,
      attachment_name: attachment_name,
      variant_names: variant_names,
      concurrency: concurrency,
      progress: progress_bar
    ) do |record, error|
      progress_bar.log "ERROR: #{error.class}: #{error.message}"
      progress_bar.log "Failed on #{model.name.downcase} ID: #{record.id}"
    end

    progress_bar.finish unless progress_bar.finished?
  end

  desc "Create all variants for game covers in the database."
  task covers: :environment do
    backfill.call(Game, :cover, Game::COVER_SIZES.keys)
  end

  desc "Create all variants for user avatars in the database."
  task avatars: :environment do
    backfill.call(User, :avatar, User::AVATAR_SIZES.keys)
  end

  desc "Create all variants for covers and avatars in the database."
  task create: :environment do
    Rake::Task['active_storage:vglist:variants:covers'].invoke
    Rake::Task['active_storage:vglist:variants:avatars'].invoke
  end
end
