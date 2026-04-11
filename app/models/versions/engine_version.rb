# frozen_string_literal: true

module Versions
  class EngineVersion < PaperTrail::Version
    self.table_name = :engine_versions
  end
end
