# Only attempt to create variants of PNG and JPEG images, don't try to
# generate webp variants. This can be changed in the future if we switch to
# vips.
#
# The default for this value includes various other content types as well, but
# we don't use any of them.
Rails.application.config.active_storage.variable_content_types = ['image/png', 'image/jpeg']

# An array of content types in which variants can be processed without being
# converted to the fallback PNG format. This is set here explicitly to prevent
# the usage of gifs or any other formats from future Rails versions.
Rails.application.config.active_storage.web_image_content_types = ['image/png', 'image/jpeg']

# TODO: The default is 5 minutes, but we want them to never expire, maybe?
# Rails.application.config.active_storage.service_urls_expire_in = nil

# Upload new variants before saving their records, so their public URLs never
# point at a file that doesn't exist yet. See
# lib/active_storage/upload_variant_before_record.rb.
Rails.application.config.to_prepare do
  require Rails.root.join('lib/active_storage/upload_variant_before_record').to_s
  ActiveStorage::VariantWithRecord.prepend(ActiveStorage::UploadVariantBeforeRecord)
end
