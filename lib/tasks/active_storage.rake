# typed: false
namespace 'active_storage:vglist' do
  desc "Remove any attachments where the blob has a content type other than PNG or JPG."
  task clean: :environment do
    # Get blobs where the content type is an invalid type (e.g. webp) and
    # they're associated with an attachment somehow.
    # Ideally this should never happen, but somehow it occasionally does. Need
    # to investigate this more.
    blobs = ActiveStorage::Blob.joins(:attachments).where.not(content_type: ['image/png', 'image/jpeg', 'image/jpg'])

    blobs.each do |blob|
      # They should only have one each, but do all of them just in case
      blob.attachments.each do |attachment|
        case attachment.record_type
        when 'Game'
          Game.find(attachment.record_id).cover.purge
        when 'User'
          User.find(attachment.record_id).avatar.purge
        else
          raise StandardError, "Invalid record type for attachment: #{attachment.record_type}."
        end
      end
    end
  end
end
