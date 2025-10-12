# Rails 6.1 changes the way ActiveStorage works so that variants are
# tracked in the database. The intent of this task is to create the
# necessary variants for all game covers and user avatars in our database.
# This way, the user isn't creating dozens of variant records as they
# browse the site. We want to create them ahead-of-time, when we deploy
# the change to track variants.
#
# This is also useful because - until a change made to vglist in late 2025,
# importing new covers from IGDB did not auto-process them with variants.
# This task can be used to rectify that mistake.
namespace 'active_storage:vglist:variants' do
  require 'ruby-progressbar'

  desc "Create all variants for game covers in the database."
  task covers: :environment do
    image_sizes = Game::COVER_SIZES.keys

    # Only get games with covers that are variable (image types that can be resized)
    # and don't already have all variants created
    games = Game.joins(:cover_attachment)
                .joins("JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id")
                .where(active_storage_blobs: { content_type: ActiveStorage.variable_content_types })
                .where("(
                  SELECT COUNT(*)
                  FROM active_storage_variant_records
                  WHERE blob_id = active_storage_blobs.id
                ) < ?", image_sizes.length)
    puts 'Creating game cover variants...'

    games_progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Disable logging in production to prevent log spam.
    Rails.logger.level = 2 if Rails.env.production?

    games.find_in_batches(batch_size: 100) do |batch|
      batch.each do |game|
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            image_sizes.each do |size|
              # Use .processed so it only processes if necessary (some of them may not need to be re-processed)
              game.sized_cover(size)&.processed
            end
          # Rescue MiniMagick errors if they occur so that they don't block the
          # task from continuing.
          rescue MiniMagick::Error => e
            games_progress_bar.log "ERROR: #{e.message}"
            games_progress_bar.log "Failed on game ID: #{game.id}"
          end
          games_progress_bar.increment
        end
      end
    end

    games_progress_bar.finish unless games_progress_bar.finished?
  end

  desc "Create all variants for user avatars in the database."
  task avatars: :environment do
    image_sizes = User::AVATAR_SIZES.keys

    # Only get users with avatars that are variable (image types that can be resized).
    users = User.joins(:avatar_attachment)
                .joins("JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id")
                .where(active_storage_blobs: { content_type: ActiveStorage.variable_content_types })
    puts 'Creating user avatar variants...'

    users_progress_bar = ProgressBar.create(
      total: users.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Disable logging in production to prevent log spam.
    Rails.logger.level = 2 if Rails.env.production?

    users.find_in_batches(batch_size: 100) do |batch|
      batch.each do |user|
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            image_sizes.each do |size|
              # Use .processed so it only processes if necessary
              user.sized_avatar(size)&.processed
            end
          # Rescue MiniMagick errors if they occur so that they don't block the
          # task from continuing.
          rescue MiniMagick::Error => e
            users_progress_bar.log "ERROR: #{e.message}"
            users_progress_bar.log "Failed on user ID: #{user.id}"
          end
          users_progress_bar.increment
        end
      end
    end

    users_progress_bar.finish unless users_progress_bar.finished?
  end

  desc "Create all variants for covers and avatars in the database."
  task create: :environment do
    Rake::Task['active_storage:vglist:variants:covers'].invoke
    Rake::Task['active_storage:vglist:variants:avatars'].invoke
  end
end
