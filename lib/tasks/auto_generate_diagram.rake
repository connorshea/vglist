# NOTE: Only doing this in development as some production environments (Heroku)
#   are sensitive to local FS writes, and besides -- it's just not proper
#   to have a dev-mode tool do its thing in production.
RailsERD.load_tasks if Rails.env.development?
