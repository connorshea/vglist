# typed: strict
# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters += [
  :password,
  # Filter ActiveStorage blob keys so that the logs aren't full of
  # as much garbage.
  :encoded_key,
  :signed_blob_id,
  :variation_key,
  :api_token,
  :encrypted_api_token,
  :secret
]
