# typed: true
# Only attempt to create variants of PNG and JPEG images, don't try to
# generate webp variants. This can be changed in the future if we switch to
# vips or update ImageMagick to support webp.
#
# The default for this value includes various other content types as well, but
# we don't use any of them.
Rails.application.config.active_storage.variable_content_types = ['image/png', 'image/jpeg']

# An array of content types in which variants can be processed without being
# converted to the fallback PNG format. This is set here explicitly to prevent
# the usage of gifs or any other formats from future Rails versions.
Rails.application.config.active_storage.web_image_content_types = ['image/png', 'image/jpeg']
