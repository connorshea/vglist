# frozen_string_literal: true

# Looks up a named variant of an image (e.g. a game cover's `:small` size)
# without ever creating it mid-request.
#
# `attachment.variant(name).processed` downloads the original, resizes it and
# uploads the result when the variant doesn't exist yet. That's fine for one
# image, but a page of covers that were never resized spends seconds per cover
# doing it, which runs past the GraphQL query timeout. Instead, return the
# original image for now and let ActiveStorage::TransformJob create the variant
# in the background, the same way `preprocessed: true` variants are created.
module ReadyVariant
  # @param attached [ActiveStorage::Attached::One] e.g. `game.cover`.
  # @param name [Symbol] One of the attachment's named variants.
  # @return [ActiveStorage::VariantWithRecord, ActiveStorage::Attached::One, nil]
  #   The variant if it exists, otherwise the original image, or nil when
  #   nothing is attached. Both respond to `url`.
  def self.for(attached, name)
    return nil unless attached.attached?
    # Images we can't resize (e.g. a GIF) only have the original.
    return attached unless attached.variable?

    variant = attached.variant(name)
    # `image` is only present once the variant has been created and stored.
    return variant if variant.image.present?

    enqueue_transform(variant)
    attached
  end

  # Queue the variant once per process per hour, so a page that's reloaded
  # (or shown to many people) doesn't queue the same work over and over.
  def self.enqueue_transform(variant)
    key = "ready_variant/#{variant.blob.id}/#{variant.variation.digest}"
    return unless Rails.cache.write(key, true, unless_exist: true, expires_in: 1.hour)

    ActiveStorage::TransformJob.perform_later(variant.blob, variant.variation.transformations)
  end
  private_class_method :enqueue_transform
end
