# typed: false

# Rails 6.1 changes the way ActiveStorage works so that variants are
# tracked in the database. The intent of this task is to create the
# necessary variants for all game covers and user avatars in our database.
# This way, the user isn't creating dozens of variant records as they
# browse the site. We want to create them ahead-of-time, when we deploy
# the change to track variants.
namespace 'active_storage:vglist:variants' do
  require 'ruby-progressbar'
  require 'parallel'

  desc "Create all variants for covers and avatars in the database."
  task create: :environment do
    games = Game.joins(:cover_attachment)
    puts 'Creating game cover variants...'

    # Use the configured max number of threads, with 2 leftover for web requests.
    # Clamp it to 1 if the configured max threads is 2 or less for whatever reason.
    thread_count = [(ENV.fetch('RAILS_MAX_THREADS', 5).to_i - 2), 1].max

    games_progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Disable logging in production to prevent log spam.
    Rails.logger.level = 2 if Rails.env.production?

    Parallel.each(games, in_threads: thread_count) do |game|
      ActiveRecord::Base.connection_pool.with_connection do
        [:small, :medium, :large].each do |size|
          game.sized_cover(size).process
        end
        games_progress_bar.increment
      end
    end

    games_progress_bar.finish unless games_progress_bar.finished?

    users = User.joins(:avatar_attachment)
    puts 'Creating user avatar variants...'

    users_progress_bar = ProgressBar.create(
      total: users.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    Parallel.each(users, in_threads: thread_count) do |user|
      ActiveRecord::Base.connection_pool.with_connection do
        [:small, :medium, :large].each do |size|
          user.sized_avatar(size).process
        end
        users_progress_bar.increment
      end
    end

    users_progress_bar.finish unless users_progress_bar.finished?
  end
end
