# frozen_string_literal: true

# Creates the named variants (small/medium/large) for every existing game cover
# and user avatar that doesn't have them yet, so nobody has to wait for one to
# be generated mid-request. New uploads get theirs in the background, see the
# `preprocessed: true` variants on Game and User.
#
# Safe to stop and re-run: images that already have every variant are
# skipped. Works on a few images at a time; set CONCURRENCY to change how
# many (default 3, capped by the database pool size).
#
#   CONCURRENCY=3 bundle exec rake active_storage:vglist:variants:create
namespace 'active_storage:vglist:variants' do
  require 'ruby-progressbar'

  # Records of `model` whose `attachment_name` is a resizable image that is
  # missing at least one of `variant_count` variants.
  variants_missing = lambda do |model, attachment_name, variant_count|
    model.joins(:"#{attachment_name}_attachment")
         .joins("JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id")
         .where(active_storage_blobs: { content_type: ActiveStorage.variable_content_types })
         .where("(
           SELECT COUNT(*)
           FROM active_storage_variant_records
           WHERE blob_id = active_storage_blobs.id
         ) < ?", variant_count)
         .preload("#{attachment_name}_attachment": { blob: :variant_records })
  end

  backfill = lambda do |model, attachment_name, variant_names|
    records = variants_missing.call(model, attachment_name, variant_names.size)
    concurrency = ENV.fetch('CONCURRENCY', 3).to_i

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
