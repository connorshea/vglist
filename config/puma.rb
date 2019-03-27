# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "production" }

# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"
activate_control_app

on_worker_boot do
  require "active_record"
  begin
    ActiveRecord::Base.connection.disconnect!
  rescue StandardError
    ActiveRecord::ConnectionNotEstablished
  end
  ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!
