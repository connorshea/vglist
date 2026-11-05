# frozen_string_literal: true

# Restrict which image formats libvips is willing to load.
#
# By default libvips sniffs the actual bytes of a file and routes it to
# whichever loader matches (SVG, PDF, HEIF, TIFF, ...), regardless of the
# declared content type. Several of those loaders are a large, historically
# CVE-prone attack surface for untrusted uploads. We only ever accept and
# process PNG and JPEG (see `variable_content_types` in
# `config/initializers/active_storage.rb`), so we allowlist just those loaders
# and block everything else at the libvips layer.
#
# This is defense-in-depth *below* the application-level
# `content_type: { spoofing_protection: true }` validation on avatars and game
# covers (which sniffs real content via Marcel, not libvips). It is not a
# replacement for that validation.
#
# `Vips.block` is only available on libvips >= 8.13. We deliberately do NOT
# degrade gracefully: if the allowlist can't be enforced we fail at boot rather
# than run with every loader silently enabled.
unless Vips.respond_to?(:block)
  raise "libvips >= 8.13 is required to restrict image loaders " \
        "(Vips.block is unavailable on #{Vips::LIBRARY_VERSION}). Upgrade libvips."
end

# Block every loader, then re-enable only the formats we accept. Keep this
# list in sync with `variable_content_types`: image/jpeg + image/png.
Vips.block('VipsForeignLoad', true)
Vips.block('VipsForeignLoadJpeg', false)
Vips.block('VipsForeignLoadPng', false)
