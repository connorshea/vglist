# typed: false
namespace 'active_storage:vglist:clean' do
  desc "Remove any attachments where the blob has a content type other than PNG or JPG."
  task bad_content_types: :environment do
    # Get blobs where the content type is an invalid type (e.g. webp) and
    # they're associated with an attachment somehow.
    # Ideally this should never happen, but somehow it occasionally does. Need
    # to investigate this more.
    blobs = ActiveStorage::Blob.joins(:attachments).where.not(content_type: ['image/png', 'image/jpeg', 'image/jpg'])

    puts "Found #{blobs.count} ActiveStorage::Blobs with a bad content type."

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

    puts "Purged all ActiveStorage::Blobs with a bad content type."
  end

  desc "Remove any blobs without an associated attachment."
  task orphan_blobs: :environment do
    # Find all orphan blobs so they can be purged.
    orphan_blobs = ActiveStorage::Blob.where.missing(:attachments)

    puts "Found #{orphan_blobs.count} orphan ActiveStorage::Blobs."

    # Purge all the orphan blobs.
    orphan_blobs.each(&:purge)

    puts "Purged all orphan ActiveStorage::Blobs."
  end

  desc "Run all ActiveStorage cleaning tasks."
  task all: :environment do
    Rake::Task['active_storage:vglist:clean:bad_content_types'].invoke
    Rake::Task['active_storage:vglist:clean:orphan_blobs'].invoke
  end
end
