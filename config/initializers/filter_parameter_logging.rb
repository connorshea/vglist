# typed: strict
# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
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
