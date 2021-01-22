# typed: true
module Versions
  class GenreVersion < PaperTrail::Version
    self.table_name = :genre_versions
  end
end
