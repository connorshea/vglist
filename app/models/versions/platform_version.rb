# typed: strict
module Versions
  class PlatformVersion < PaperTrail::Version
    self.table_name = :platform_versions
  end
end
