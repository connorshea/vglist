# frozen_string_literal: true

module Versions
  class GameVersion < PaperTrail::Version
    self.table_name = :game_versions
  end
end
