# typed: strict
module Types
  class LiveSiteStatisticType < Types::BaseObject
    description <<~MARKDOWN
      Live-updated site statistics for the vglist database.
    MARKDOWN

    implements Types::SiteStatisticItem
  end
end
