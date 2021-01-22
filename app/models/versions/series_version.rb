# typed: strict
module Versions
  class SeriesVersion < PaperTrail::Version
    self.table_name = :series_versions
  end
end
