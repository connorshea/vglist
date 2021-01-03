# typed: false
# Define the overall Rails default URL options based on action_mailer's
# default URL options, which are set in the environment/*.rb files.
#
# Surprisingly, I wasn't able to figure out a better way to accomplish this.
# This is necessary for the URL generation to work in GraphQL.
Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
