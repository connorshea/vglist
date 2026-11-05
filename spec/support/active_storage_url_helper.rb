# frozen_string_literal: true

# GraphQL returns an attachment variant's service URL, which for the Disk
# service in tests is built from the request's host (see
# `ActiveStorage::SetCurrent` in GraphqlController). Request specs hit
# `http://www.example.com`, so build the expected URL with the same options.
module ActiveStorageUrlHelper
  def variant_url(variant)
    ActiveStorage::Current.set(url_options: { protocol: 'http://', host: 'www.example.com', port: 80 }) do
      variant.url
    end
  end
end
