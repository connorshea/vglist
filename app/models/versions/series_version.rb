# frozen_string_literal: true

module Versions
  class SeriesVersion < PaperTrail::Version
    self.table_name = :series_versions
  end
end
