# frozen_string_literal: true

# `includes` specs for eagerly loading an Active Storage attachment.
#
# `includes(cover_attachment: :blob)` looks complete but isn't. With
# `ActiveStorage.track_variants` enabled — the default — rendering a variant URL
# also reads `blob.variant_records`, so the truncated form preloads the
# attachment and its blob and then still fires one variant lookup per record.
# It half-works, which is why it's easy to write by mistake.
#
# Rails' generated `with_attached_*` scopes expand to the full chain below.
# Prefer those scopes when the attachment hangs off the relation being loaded
# (`User.all.with_attached_avatar`); use these constants when the attachment is
# nested inside a larger `includes` and the scope can't be applied
# (`includes(user: AttachmentPreloads::AVATAR)`).
module AttachmentPreloads
  # The blob and everything needed to resolve a variant of it.
  BLOB = { blob: { variant_records: { image_attachment: :blob } } }.freeze

  # For `Game#cover`.
  COVER = { cover_attachment: BLOB }.freeze

  # For `User#avatar`.
  AVATAR = { avatar_attachment: BLOB }.freeze
end
